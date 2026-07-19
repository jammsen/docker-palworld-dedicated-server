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

function clientIp(headerValue: string | undefined, fallback: string): string {
  return headerValue?.split(",")[0]?.trim() || fallback;
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
    c.header("Content-Security-Policy", "default-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:");
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
    const ip = clientIp(c.req.header("x-forwarded-for"), "unknown");
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
      log.warn(`>>> Panel login failed for user '${username}'`);
      return c.html(LoginPage({ t, language, error: "invalid" }), 401);
    }
    auth.recordSuccess(ip);
    setCookie(c, SESSION_COOKIE, auth.createSession(), {
      httpOnly: true,
      sameSite: "Strict",
      path: "/",
      secure: c.req.header("x-forwarded-proto") === "https",
    });
    log.info(">>> Panel login successful");
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
    return c.redirect(c.req.header("referer") ?? "/");
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
    return c.redirect(`/settings?saved=${changes}`);
  });

  app.post("/settings/reset", async (c) => {
    if (settingsReadOnly) return c.redirect("/settings");
    const form = await c.req.parseBody();
    const key = typeof form._reset === "string" ? form._reset : "";
    if (key === "__all__") {
      await settings.resetAllOverrides();
      log.info(">>> Panel reset all settings-overrides");
    } else if (settingsByKey.has(key)) {
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

  app.post("/settings/restart", async (c) => {
    const t = c.get("t");
    log.warn(">>> Panel triggered a server restart");
    try {
      await client.announce("Server restart requested from the web panel");
      await client.save();
      await client.shutdown(10, "Saving done. Server restarting...");
    } catch (error) {
      log.warn(`>>> Restart via REST API failed: ${String(error)}`);
    }
    return c.html(`<meta http-equiv="refresh" content="5; url=/settings" /><p>${t("settings.restartTriggered")}</p>`);
  });

  return app;
}
