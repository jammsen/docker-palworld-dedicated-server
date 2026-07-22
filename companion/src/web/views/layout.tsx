import type { Child } from "hono/jsx";

export interface LayoutProps {
  t: (key: string) => string;
  language: string;
  activeNav?: "dashboard" | "players" | "settings";
  autoRefreshSeconds?: number;
  csrf?: string;
  children?: Child;
}

export function Layout({ t, language, activeNav, autoRefreshSeconds, csrf, children }: LayoutProps) {
  return (
    <html lang={language}>
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        {autoRefreshSeconds ? <meta http-equiv="refresh" content={String(autoRefreshSeconds)} /> : null}
        <title>{t("app.title")}</title>
        <link rel="stylesheet" href="/assets/style.css" />
        <script src="/assets/enhance.js" defer></script>
      </head>
      <body>
        <header class="topbar">
          <span class="brand">🛡️ {t("app.title")}</span>
          {activeNav ? (
            <nav>
              <a href="/" class={activeNav === "dashboard" ? "active" : ""}>
                {t("nav.dashboard")}
              </a>
              <a href="/players" class={activeNav === "players" ? "active" : ""}>
                {t("nav.players")}
              </a>
              <a href="/settings" class={activeNav === "settings" ? "active" : ""}>
                {t("nav.settings")}
              </a>
              <span class="spacer" />
              <form method="post" action="/language" class="inline">
                {csrf ? <input type="hidden" name="_csrf" value={csrf} /> : null}
                <select name="lang" data-autosubmit>
                  <option value="en" selected={language === "en"}>
                    English
                  </option>
                  <option value="zh-CN" selected={language === "zh-CN"}>
                    中文
                  </option>
                </select>
                <button type="submit" class="linklike" data-autosubmit-fallback>
                  ✓
                </button>
              </form>
              <form method="post" action="/logout" class="inline">
                {csrf ? <input type="hidden" name="_csrf" value={csrf} /> : null}
                <button type="submit" class="linklike">
                  {t("nav.logout")}
                </button>
              </form>
            </nav>
          ) : null}
        </header>
        <main>{children}</main>
      </body>
    </html>
  );
}
