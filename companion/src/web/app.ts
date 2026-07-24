import { getConnInfo } from "@hono/node-server/conninfo";
import { Hono } from "hono";
import type { Context } from "hono";
import { deleteCookie, getCookie, setCookie } from "hono/cookie";
import type { CompanionConfig } from "../config.js";
import { log } from "../logger.js";
import type { MetricsCollector } from "../metrics/collector.js";
import { parseBanlist, type BanlistEntry } from "../palworld/banlist.js";
import type { PalworldClient } from "../palworld/client.js";
import { settingsByKey, validateSettingValue } from "../settings/schema.js";
import type { SettingsStore } from "../settings/store.js";
import { AuthService, SESSION_COOKIE } from "./auth.js";
import { enhanceJs } from "./enhance.js";
import { availableLanguages, resolveLanguage, translator } from "./i18n.js";
import { DashboardPage } from "./views/dashboard.js";
import { LoginPage } from "./views/login.js";
import { PlayersPage } from "./views/players.js";
import { SettingsPage } from "./views/settings.js";

// Bundled at build time - no static file serving, no filesystem paths to resolve
import styleCss from "../../public/style.css";

const SNAPSHOT_MAX_AGE_MS = 5_000;
const LANG_COOKIE = "companion_lang";

export interface AppDeps {
  auth: AuthService;
  collector: MetricsCollector;
  settings: SettingsStore;
  client: PalworldClient;
}

export interface AppEnv {
  Variables: {
    t: (key: string) => string;
    language: string;
  };
}

// Socket address is the source of truth; X-Forwarded-For is client-controlled
// on direct deployments and only honored behind an explicit trusted proxy.
function clientIp(c: Context, trustProxy: boolean): string {
  if (trustProxy) {
    // Rightmost entry: appended by the trusted proxy itself. Leftmost entries
    // travel with the request and stay client-spoofable even behind a proxy.
    const forwarded = c.req.header("x-forwarded-for")?.split(",").at(-1)?.trim();
    if (forwarded) return forwarded;
  }
  try {
    return getConnInfo(c).remote.address ?? "unknown";
  } catch {
    return "unknown";
  }
}

// Minimal app served when the panel is disabled (Discord-only deployments):
// the health endpoint stays available for container healthchecks either way
export function createHealthApp(config: CompanionConfig, version: string): Hono {
  const app = new Hono();
  app.get("/api/health", (c) =>
    c.json({
      status: "ok",
      version,
      panel: false,
      discord: config.discord !== null,
    }),
  );
  return app;
}

export function createApp(config: CompanionConfig, version: string, deps: AppDeps): Hono<AppEnv> {
  const { auth, collector, settings, client } = deps;
  const panel = config.panel;
  if (!panel) throw new Error("createApp called without panel config");

  const app = new Hono<AppEnv>();

  app.use("*", async (c, next) => {
    c.header("Cache-Control", "no-store");
    c.header("X-Content-Type-Options", "nosniff");
    // 'unsafe-inline' styles: the usage bars set their width via a style attribute
    c.header(
      "Content-Security-Policy",
      "default-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; frame-ancestors 'none'",
    );
    const cookieLang = getCookie(c, LANG_COOKIE);
    const language = resolveLanguage(cookieLang, c.req.header("accept-language"), panel.defaultLanguage);
    c.set("language", language);
    c.set("t", translator(language));
    await next();
  });

  app.get("/assets/style.css", (c) => c.body(styleCss, 200, { "Content-Type": "text/css" }));
  app.get("/assets/enhance.js", (c) => c.body(enhanceJs, 200, { "Content-Type": "text/javascript" }));

  // Unauthenticated liveness endpoint for CI smoke tests and user monitoring
  app.get("/api/health", (c) =>
    c.json({
      status: "ok",
      version,
      panel: true,
      discord: config.discord !== null,
    }),
  );

  app.get("/login", (c) => c.html(LoginPage({ t: c.get("t"), language: c.get("language") })));

  app.post("/login", async (c) => {
    const ip = clientIp(c, panel.trustProxy);
    const t = c.get("t");
    const language = c.get("language");
    if (auth.isLockedOut(ip)) {
      return c.html(LoginPage({ t, language, error: "ratelimited" }), 429);
    }
    const form = await c.req.parseBody();
    const username = typeof form.username === "string" ? form.username : "";
    const password = typeof form.password === "string" ? form.password : "";
    if (!auth.verifyLogin(username, password)) {
      auth.recordFailure(ip);
      // Strip control characters and cap length so user input cannot forge log lines
      const safeUser = username.replace(/[^\x20-\x7e]/g, "?").slice(0, 32);
      log.warn(`>>> Panel login failed for user '${safeUser}' from ${ip}`);
      return c.html(LoginPage({ t, language, error: "invalid" }), 401);
    }
    auth.recordSuccess(ip);
    setCookie(c, SESSION_COOKIE, auth.createSession(), {
      httpOnly: true,
      sameSite: "Strict",
      path: "/",
      secure: panel.trustProxy && c.req.header("x-forwarded-proto") === "https",
    });
    log.info(`>>> Panel login successful from ${ip}`);
    return c.redirect("/");
  });

  // Everything below requires a valid session
  app.use("*", async (c, next) => {
    if (!auth.verifySession(getCookie(c, SESSION_COOKIE))) {
      if (c.req.path.startsWith("/api/")) {
        return c.json({ error: "unauthorized" }, 401);
      }
      return c.redirect("/login");
    }
    await next();
  });

  // CSRF: SameSite=Strict plus a per-session synchronizer token on all POSTs
  app.use("*", async (c, next) => {
    if (c.req.method === "POST" && c.req.path !== "/login") {
      const form = await c.req.parseBody();
      const token = typeof form._csrf === "string" ? form._csrf : undefined;
      if (!auth.verifyCsrf(getCookie(c, SESSION_COOKIE), token)) {
        return c.text("CSRF token invalid", 403);
      }
    }
    await next();
  });

  app.post("/logout", (c) => {
    deleteCookie(c, SESSION_COOKIE, { path: "/" });
    return c.redirect("/login");
  });

  app.post("/language", async (c) => {
    const form = await c.req.parseBody();
    const lang = typeof form.lang === "string" ? form.lang : "en";
    if (availableLanguages.includes(lang)) {
      setCookie(c, LANG_COOKIE, lang, { path: "/", sameSite: "Strict" });
    }
    // Referer is client-supplied: keep only path+query so the redirect can never leave the panel
    let target = "/";
    try {
      const url = new URL(c.req.header("referer") ?? "/", "http://panel.invalid");
      target = url.pathname + url.search;
    } catch {
      target = "/";
    }
    return c.redirect(target);
  });

  app.get("/", async (c) => {
    const snapshot = await collector.getFresh(SNAPSHOT_MAX_AGE_MS);
    const csrf = auth.csrfToken(getCookie(c, SESSION_COOKIE) ?? "");
    return c.html(DashboardPage({ t: c.get("t"), language: c.get("language"), snapshot, csrf }));
  });

  const readBanlist = async (): Promise<BanlistEntry[]> => {
    try {
      const { readFile } = await import("node:fs/promises");
      return parseBanlist(await readFile(config.banlistFile, "utf8"));
    } catch {
      return [];
    }
  };

  app.get("/players", async (c) => {
    const snapshot = await collector.getFresh(SNAPSHOT_MAX_AGE_MS);
    const csrf = auth.csrfToken(getCookie(c, SESSION_COOKIE) ?? "");
    const result = c.req.query("result");
    return c.html(
      PlayersPage({
        t: c.get("t"),
        language: c.get("language"),
        snapshot,
        csrf,
        banlist: await readBanlist(),
        ...(result === "kicked" || result === "banned" || result === "unbanned" || result === "failed"
          ? { actionResult: result }
          : {}),
      }),
    );
  });

  const moderationAction = (action: "kick" | "ban" | "unban") => async (c: Context<AppEnv>) => {
    const form = await c.req.parseBody();
    const userid = typeof form.userid === "string" ? form.userid.trim() : "";
    if (!/^[A-Za-z0-9_]+$/.test(userid)) {
      return c.redirect("/players?result=failed");
    }
    try {
      if (action === "kick") await client.kick(userid, "Kicked by an admin via the web panel");
      else if (action === "ban") await client.ban(userid, "Banned by an admin via the web panel");
      else await client.unban(userid);
      log.warn(`>>> Panel moderation: ${action} ${userid}`);
      const results = { kick: "kicked", ban: "banned", unban: "unbanned" } as const;
      return c.redirect(`/players?result=${results[action]}`);
    } catch (error) {
      log.warn(`>>> Panel moderation ${action} failed: ${String(error)}`);
      return c.redirect("/players?result=failed");
    }
  };

  app.post("/players/kick", moderationAction("kick"));
  app.post("/players/ban", moderationAction("ban"));
  app.post("/players/unban", moderationAction("unban"));

  app.get("/api/status", async (c) => {
    const snapshot = await collector.getFresh(SNAPSHOT_MAX_AGE_MS);
    return c.json(snapshot);
  });

  const settingsReadOnly = config.serverSettingsMode !== "auto";

  const renderSettings = async (c: Context<AppEnv>, extra: { saved?: number; errors?: string[] } = {}) => {
    const effective = await settings.effectiveSettings();
    const csrf = auth.csrfToken(getCookie(c, SESSION_COOKIE) ?? "");
    return c.html(
      SettingsPage({
        t: c.get("t"),
        language: c.get("language"),
        csrf,
        settings: effective,
        readOnly: settingsReadOnly,
        restartPending: await settings.restartPending(config.gameSettingsFile),
        ...extra,
      }),
    );
  };

  app.get("/settings", (c) => {
    const saved = c.req.query("saved");
    return renderSettings(c, saved ? { saved: Number.parseInt(saved, 10) } : {});
  });

  app.post("/settings/save", async (c) => {
    if (settingsReadOnly) return c.redirect("/settings");
    const form = await c.req.parseBody();
    const submitted = new Map<string, string>();
    const errors: string[] = [];
    for (const [key, value] of Object.entries(form)) {
      const spec = settingsByKey.get(key);
      if (!spec || spec.excluded || typeof value !== "string") continue;
      const result = validateSettingValue(spec, value);
      if (result.ok) {
        submitted.set(key, value);
      } else {
        errors.push(`${key}: ${result.reason}`);
      }
    }
    if (errors.length > 0) {
      return renderSettings(c, { errors });
    }
    const changes = await settings.applySubmission(submitted);
    log.info(`>>> Panel saved settings (${changes} override changes)`);
    if (changes > 0) {
      await collector.recordEvent({ at: Date.now(), type: "settings" });
    }
    return c.redirect(`/settings?saved=${changes}`);
  });

  app.post("/settings/reset", async (c) => {
    if (settingsReadOnly) return c.redirect("/settings");
    const form = await c.req.parseBody();
    const key = typeof form._reset === "string" ? form._reset : "";
    const spec = settingsByKey.get(key);
    if (key === "__all__") {
      await settings.resetAllOverrides();
      log.info(">>> Panel reset all settings-overrides");
    } else if (spec && !spec.excluded) {
      await settings.resetOverride(key);
      log.info(`>>> Panel reset settings-override for ${key}`);
    }
    return c.redirect("/settings");
  });

  app.get("/settings/export", async (c) => {
    const { readFile } = await import("node:fs/promises");
    const template = await readFile(config.envTemplateFile, "utf8").catch(() => undefined);
    return c.body(await settings.exportEnv(template), 200, {
      "Content-Type": "text/plain; charset=utf-8",
      "Content-Disposition": 'attachment; filename="palworld-settings.env"',
    });
  });

  app.post("/actions/restart", async (c) => {
    const t = c.get("t");
    try {
      await client.announce("Server restart requested from the web panel");
      await client.save();
      await client.shutdown(10, "Saving done. Server restarting...");
    } catch (error) {
      // Do not record the event or claim success when the REST call failed
      log.warn(`>>> Restart via REST API failed: ${String(error)}`);
      return c.html(`<meta http-equiv="refresh" content="5; url=/" /><p>${t("settings.restartFailed")}</p>`, 502);
    }
    log.warn(">>> Panel triggered a server restart");
    await collector.recordEvent({ at: Date.now(), type: "restart" });
    return c.html(`<meta http-equiv="refresh" content="5; url=/" /><p>${t("settings.restartTriggered")}</p>`);
  });

  return app;
}
