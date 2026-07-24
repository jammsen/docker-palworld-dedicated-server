import { serve } from "@hono/node-server";
import { mkdir } from "node:fs/promises";
import { parseConfig } from "./config.js";
import { log, setDebug } from "./logger.js";
import { createApp, createHealthApp } from "./web/app.js";

// Injected by build.mjs; fallback keeps `tsx watch` working in dev
declare const COMPANION_VERSION: string | undefined;
const VERSION = typeof COMPANION_VERSION === "string" ? COMPANION_VERSION : "dev";

if (process.argv.includes("--version")) {
  console.log(`palworld-companion ${VERSION}`);
  process.exit(0);
}

const config = parseConfig(process.env);
setDebug(config.debug);

log.info(">>> Starting companion service");
log.base(`> palworld-companion ${VERSION}`);

for (const warning of config.warnings) {
  log.warn(`>>> ${warning}`);
}

if (!config.panel && !config.discord) {
  // The shell only starts us when a feature flag is on; ending up here means the
  // feature refused to start (e.g. missing password). Stay alive instead of
  // exiting so the supervising loop does not restart-spam every few seconds.
  log.error(">>> No feature could be enabled - companion service is idle (fix the configuration and restart the container)");
  setInterval(() => {
    log.warn(">>> Companion service is still idle due to configuration errors");
  }, 3_600_000);
} else {
  await mkdir(config.dataDir, { recursive: true });

  const { StateStore } = await import("./state.js");
  const { PalworldClient } = await import("./palworld/client.js");
  const { MetricsCollector } = await import("./metrics/collector.js");
  const { HostProcMetricsSource } = await import("./sys/metrics-source.js");

  const state = new StateStore(config.dataDir);
  await state.load();
  const client = new PalworldClient(config.restapi);
  const collector = new MetricsCollector(config, client, state, new HostProcMetricsSource());

  const shutdownHooks: Array<() => Promise<void> | void> = [];

  // The HTTP listener is always on: with the panel it serves the full app, in
  // Discord-only deployments just /api/health - so a container healthcheck
  // works no matter which feature is enabled
  let app: { fetch: Parameters<typeof serve>[0]["fetch"] };
  if (config.panel) {
    const { AuthService } = await import("./web/auth.js");
    const { SettingsStore } = await import("./settings/store.js");
    const secret = await AuthService.ensureSecret(state);
    const auth = new AuthService(secret, config.panel.username, config.panel.password);
    const settings = new SettingsStore(config.dataDir, process.env);
    app = createApp(config, VERSION, { auth, collector, settings, client });
  } else {
    app = createHealthApp(config, VERSION);
  }
  const server = serve({ fetch: app.fetch, port: config.listenPort, hostname: "0.0.0.0" }, (info) => {
    if (config.panel) log.success(`>>> Web panel listening on port ${info.port}`);
    else log.info(`>>> Health endpoint listening on port ${info.port} (panel disabled)`);
  });
  shutdownHooks.push(() => new Promise<void>((resolve) => server.close(() => resolve())));

  if (config.discord) {
    const { startDiscordStatus } = await import("./discord/updater.js");
    const stop = await startDiscordStatus(config, { collector, state });
    shutdownHooks.push(stop);
  }

  let shuttingDown = false;
  const shutdown = async (signal: string) => {
    if (shuttingDown) return;
    shuttingDown = true;
    log.warn(`>>> Companion service received ${signal}, shutting down`);
    // Give hooks (final Discord "offline" edit, server close) enough budget to
    // cover one full webhook request (10s AbortSignal timeout) plus overhead;
    // Promise.race exits immediately when the hooks finish sooner.
    const budget = new Promise((resolve) => setTimeout(resolve, 12_000));
    // Async wrapper turns a synchronously-throwing hook into a rejection so
    // one bad hook cannot bypass allSettled and skip the others
    await Promise.race([Promise.allSettled(shutdownHooks.map(async (hook) => hook())), budget]);
    process.exit(0);
  };
  process.on("SIGTERM", () => void shutdown("SIGTERM"));
  process.on("SIGINT", () => void shutdown("SIGINT"));
}
