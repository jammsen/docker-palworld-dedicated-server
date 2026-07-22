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
          const eq = param.indexOf("=");
          if (eq === -1) continue;
          if (param.slice(0, eq).trim().toLowerCase() !== "q") continue;
          // RFC 7231 qvalue: 0(.000)-1(.000). A present but malformed or
          // out-of-range value must not keep the implicit priority 1.
          const value = param.slice(eq + 1).trim();
          q = /^(?:0(?:\.\d{0,3})?|1(?:\.0{0,3})?)$/.test(value) ? Number.parseFloat(value) : 0;
        }
        return { tag, q, index };
      })
      .filter((entry) => entry.tag.length > 0 && entry.q > 0)
      .sort((a, b) => b.q - a.q || a.index - b.index);
    for (const { tag } of entries) {
      // Language tags are case-insensitive (RFC 5646) - compare lowercased
      // but always return the catalog's canonical key
      const tagLower = tag.toLowerCase();
      const exact = availableLanguages.find((lang) => lang.toLowerCase() === tagLower);
      if (exact) return exact;
      const base = tagLower.split("-")[0] ?? "";
      const match = availableLanguages.find((lang) => lang.toLowerCase() === base || lang.toLowerCase().startsWith(`${base}-`));
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
