import { Hono } from "hono";
import { deleteCookie, getCookie, setCookie } from "hono/cookie";
import type { CompanionConfig } from "../config.js";
import { log } from "../logger.js";
import type { MetricsCollector } from "../metrics/collector.js";
import { AuthService, SESSION_COOKIE } from "./auth.js";
import { availableLanguages, resolveLanguage, translator } from "./i18n.js";
import { DashboardPage } from "./views/dashboard.js";
import { LoginPage } from "./views/login.js";
import { PlayersPage } from "./views/players.js";

// Bundled at build time - no static file serving, no filesystem paths to resolve
import styleCss from "../../public/style.css";

const SNAPSHOT_MAX_AGE_MS = 5_000;
const LANG_COOKIE = "companion_lang";

export interface AppDeps {
  auth: AuthService;
  collector: MetricsCollector;
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
  const { auth, collector } = deps;
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

  app.get("/players", async (c) => {
    const snapshot = await collector.getFresh(SNAPSHOT_MAX_AGE_MS);
    const csrf = auth.csrfToken(getCookie(c, SESSION_COOKIE) ?? "");
    return c.html(PlayersPage({ t: c.get("t"), language: c.get("language"), snapshot, csrf }));
  });

  app.get("/api/status", async (c) => {
    const snapshot = await collector.getFresh(SNAPSHOT_MAX_AGE_MS);
    return c.json(snapshot);
  });

  return app;
}
