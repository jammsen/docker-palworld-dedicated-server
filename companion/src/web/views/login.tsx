import { Layout } from "./layout.js";

export interface LoginPageProps {
  t: (key: string) => string;
  language: string;
  error?: "invalid" | "ratelimited";
}

export function LoginPage({ t, language, error }: LoginPageProps) {
  return (
    <Layout t={t} language={language}>
      <div class="login-card">
        <h1>{t("login.title")}</h1>
        {error ? <p class="error">{error === "ratelimited" ? t("login.ratelimited") : t("login.error")}</p> : null}
        <form method="post" action="/login">
          <label>
            {t("login.username")}
            <input type="text" name="username" autocomplete="username" required />
          </label>
          <label>
            {t("login.password")}
            <input type="password" name="password" autocomplete="current-password" required />
          </label>
          <button type="submit">{t("login.submit")}</button>
        </form>
      </div>
    </Layout>
  );
}
