import en from "../../locales/en.json";
import zhCN from "../../locales/zh-CN.json";

export type Catalog = Record<string, string>;

const catalogs: Record<string, Catalog> = {
  en: en as Catalog,
  "zh-CN": zhCN as Catalog,
};

export const availableLanguages = Object.keys(catalogs);

export function resolveLanguage(cookieLang: string | undefined, acceptLanguage: string | undefined, fallback: string): string {
  if (cookieLang && catalogs[cookieLang]) return cookieLang;
  if (acceptLanguage) {
    for (const part of acceptLanguage.split(",")) {
      const tag = (part.split(";")[0] ?? "").trim();
      if (catalogs[tag]) return tag;
      const base = tag.split("-")[0] ?? "";
      const match = availableLanguages.find((lang) => lang === base || lang.startsWith(`${base}-`));
      if (match) return match;
    }
  }
  if (catalogs[fallback]) return fallback;
  return "en";
}

// Missing keys fall back to English so a partial catalog never breaks the UI
export function translator(language: string): (key: string) => string {
  const catalog = catalogs[language] ?? catalogs.en!;
  return (key: string) => catalog[key] ?? catalogs.en![key] ?? key;
}
