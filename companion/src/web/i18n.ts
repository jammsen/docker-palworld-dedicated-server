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
    // Honor q-weights: highest first, header order breaks ties, q=0 means "never"
    const entries = acceptLanguage
      .split(",")
      .map((part, index) => {
        const [tagRaw, ...params] = part.split(";");
        const tag = (tagRaw ?? "").trim();
        let q = 1;
        for (const param of params) {
          const match = /^\s*q=(\d+(?:\.\d+)?)\s*$/i.exec(param);
          if (match) q = Number.parseFloat(match[1]!);
        }
        return { tag, q: Number.isFinite(q) ? q : 0, index };
      })
      .filter((entry) => entry.tag.length > 0 && entry.q > 0)
      .sort((a, b) => b.q - a.q || a.index - b.index);
    for (const { tag } of entries) {
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
