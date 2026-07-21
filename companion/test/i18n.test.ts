import { describe, expect, it } from "vitest";
import { resolveLanguage, translator } from "../src/web/i18n.js";

describe("resolveLanguage", () => {
  it("prefers the cookie language", () => {
    expect(resolveLanguage("zh-CN", "en", "en")).toBe("zh-CN");
  });

  it("negotiates from Accept-Language including base-tag matches", () => {
    expect(resolveLanguage(undefined, "zh-CN,zh;q=0.9", "en")).toBe("zh-CN");
    expect(resolveLanguage(undefined, "zh", "en")).toBe("zh-CN");
    expect(resolveLanguage(undefined, "fr,en;q=0.8", "en")).toBe("en");
  });

  it("honors q-weights: order by weight and never pick q=0 entries", () => {
    expect(resolveLanguage(undefined, "en;q=0.5,zh-CN;q=0.9", "en")).toBe("zh-CN");
    expect(resolveLanguage(undefined, "zh-CN;q=0,en;q=0.8", "en")).toBe("en");
    expect(resolveLanguage(undefined, "fr;q=0.9,zh;q=0.9", "en")).toBe("zh-CN");
  });

  it("falls back to the configured default, then English", () => {
    expect(resolveLanguage(undefined, undefined, "zh-CN")).toBe("zh-CN");
    expect(resolveLanguage(undefined, undefined, "xx")).toBe("en");
  });
});

describe("translator", () => {
  it("translates known keys and falls back to English for missing ones", () => {
    const t = translator("zh-CN");
    expect(t("nav.dashboard")).toBe("仪表盘");
    const en = translator("en");
    expect(en("nav.dashboard")).toBe("Dashboard");
    expect(t("nonexistent.key")).toBe("nonexistent.key");
  });
});
