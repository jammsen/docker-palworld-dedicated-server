import { describe, expect, it } from "vitest";
import { MIN_DISCORD_INTERVAL_SECONDS, parseConfig } from "../src/config.js";

describe("parseConfig", () => {
  it("disables everything by default", () => {
    const config = parseConfig({});
    expect(config.panel).toBeNull();
    expect(config.discord).toBeNull();
    expect(config.warnings).toHaveLength(0);
  });

  it("refuses to enable the panel without a password", () => {
    const config = parseConfig({ PANEL_ENABLED: "true", PANEL_PASSWORD: "" });
    expect(config.panel).toBeNull();
    expect(config.warnings.some((w) => w.includes("PANEL_PASSWORD"))).toBe(true);
  });

  it("enables the panel with defaults applied", () => {
    const config = parseConfig({ PANEL_ENABLED: "true", PANEL_PASSWORD: "secret" });
    expect(config.panel).toEqual({
      port: 8213,
      username: "admin",
      password: "secret",
      defaultLanguage: "en",
    });
  });

  it("falls back to WEBHOOK_URL for the Discord status card", () => {
    const config = parseConfig({
      DISCORD_STATUS_ENABLED: "true",
      WEBHOOK_URL: "https://discord.com/api/webhooks/1/abc",
    });
    expect(config.discord?.webhookUrl).toBe("https://discord.com/api/webhooks/1/abc");
  });

  it("disables the Discord card without any webhook URL", () => {
    const config = parseConfig({ DISCORD_STATUS_ENABLED: "true" });
    expect(config.discord).toBeNull();
    expect(config.warnings.some((w) => w.includes("WEBHOOK_URL"))).toBe(true);
  });

  it("clamps the Discord update interval to the safety minimum", () => {
    const config = parseConfig({
      DISCORD_STATUS_ENABLED: "true",
      DISCORD_STATUS_WEBHOOK_URL: "https://discord.com/api/webhooks/1/abc",
      DISCORD_STATUS_UPDATE_INTERVAL: "1",
    });
    expect(config.discord?.updateIntervalSeconds).toBe(MIN_DISCORD_INTERVAL_SECONDS);
  });

  it("warns when features are on but the REST API is off", () => {
    const config = parseConfig({
      PANEL_ENABLED: "true",
      PANEL_PASSWORD: "secret",
      RESTAPI_ENABLED: "false",
    });
    expect(config.warnings.some((w) => w.includes("RESTAPI_ENABLED"))).toBe(true);
  });
});
