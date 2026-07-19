import { serve } from "@hono/node-server";
import { mkdir } from "node:fs/promises";
import { parseConfig } from "./config.js";
import { log, setDebug } from "./logger.js";
import { createApp } from "./web/app.js";

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

  const state = new StateStore(config.dataDir);
  await state.load();
  const client = new PalworldClient(config.restapi);
  const collector = new MetricsCollector(config, client, state);

  const shutdownHooks: Array<() => Promise<void> | void> = [];

  if (config.panel) {
    const app = createApp(config, VERSION);
    const server = serve({ fetch: app.fetch, port: config.panel.port, hostname: "0.0.0.0" }, (info) => {
      log.success(`>>> Web panel listening on port ${info.port}`);
    });
    shutdownHooks.push(() => new Promise<void>((resolve) => server.close(() => resolve())));
  }

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
    // Give hooks (final Discord "offline" edit, server close) a small budget
    const budget = new Promise((resolve) => setTimeout(resolve, 3000));
    await Promise.race([Promise.allSettled(shutdownHooks.map((hook) => hook())), budget]);
    process.exit(0);
  };
  process.on("SIGTERM", () => void shutdown("SIGTERM"));
  process.on("SIGINT", () => void shutdown("SIGINT"));
}
