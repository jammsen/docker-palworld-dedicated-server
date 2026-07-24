import { describe, expect, it } from "vitest";
import { MIN_DISCORD_INTERVAL_SECONDS, parseConfig } from "../src/config.js";

describe("parseConfig", () => {
  it("disables everything by default", () => {
    const config = parseConfig({});
    expect(config.panel).toBeNull();
    expect(config.discord).toBeNull();
    expect(config.warnings).toHaveLength(0);
  });

  it("derives sidecar paths from GAME_ROOT with a bundled-mode data-dir fallback", () => {
    const config = parseConfig({});
    expect(config.dataDir).toBe("/palworld/companion");
    expect(config.gameEventsFile).toBe("/palworld/game-events.log");
    expect(config.companionEventsFile).toBe("/palworld/companion/companion-events.log");
    expect(config.restapi.host).toBe("127.0.0.1");
  });

  it("honors COMPANION_DATA_DIR and RESTAPI_HOST for the sidecar layout", () => {
    const config = parseConfig({
      GAME_ROOT: "/palworld",
      COMPANION_DATA_DIR: "/data",
      RESTAPI_HOST: "palworld-dedicated-server",
    });
    expect(config.dataDir).toBe("/data");
    expect(config.gameEventsFile).toBe("/palworld/game-events.log");
    expect(config.companionEventsFile).toBe("/data/companion-events.log");
    expect(config.restapi.host).toBe("palworld-dedicated-server");
  });

  it("refuses to enable the panel without a password", () => {
    const config = parseConfig({ PANEL_ENABLED: "true", PANEL_PASSWORD: "" });
    expect(config.panel).toBeNull();
    expect(config.warnings.some((w) => w.includes("PANEL_PASSWORD"))).toBe(true);
  });

  it("enables the panel with defaults applied", () => {
    const config = parseConfig({ PANEL_ENABLED: "true", PANEL_PASSWORD: "secret" });
    expect(config.panel).toEqual({
      username: "admin",
      password: "secret",
      defaultLanguage: "en",
      trustProxy: false,
    });
    expect(config.listenPort).toBe(8213);
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

  it("accepts valid custom platform emojis and rejects malformed ones", () => {
    const config = parseConfig({
      DISCORD_STATUS_ENABLED: "true",
      DISCORD_STATUS_WEBHOOK_URL: "https://discord.com/api/webhooks/1/abc",
      DISCORD_STATUS_EMOJI_STEAM: "<:steam:1123581321345589012>",
      DISCORD_STATUS_EMOJI_XBOX: "not-an-emoji-token",
    });
    expect(config.discord?.platformEmoji.steam).toBe("<:steam:1123581321345589012>");
    expect(config.discord?.platformEmoji.xbox).toBeUndefined();
    expect(config.warnings.some((w) => w.includes("DISCORD_STATUS_EMOJI_XBOX"))).toBe(true);
  });

  it("accepts custom event emojis including the hyphenated updating-validate", () => {
    const config = parseConfig({
      DISCORD_STATUS_ENABLED: "true",
      DISCORD_STATUS_WEBHOOK_URL: "https://discord.com/api/webhooks/1/abc",
      DISCORD_STATUS_EMOJI_EVENT_JOIN: "<:pal_join:111>",
      DISCORD_STATUS_EMOJI_EVENT_UPDATING_VALIDATE: "<:pal_updating_validate:222>",
      DISCORD_STATUS_EMOJI_EVENT_BACKUP: "broken",
    });
    expect(config.discord?.eventEmoji.join).toBe("<:pal_join:111>");
    expect(config.discord?.eventEmoji["updating-validate"]).toBe("<:pal_updating_validate:222>");
    expect(config.discord?.eventEmoji.backup).toBeUndefined();
    expect(config.warnings.some((w) => w.includes("EMOJI_EVENT_BACKUP"))).toBe(true);
  });

  it("clamps the event amount to the stored-history range", () => {
    const base = { DISCORD_STATUS_ENABLED: "true", DISCORD_STATUS_WEBHOOK_URL: "https://discord.com/api/webhooks/1/abc" };
    expect(parseConfig({ ...base }).discord?.eventAmount).toBe(25);
    expect(parseConfig({ ...base, DISCORD_STATUS_EVENT_AMOUNT: "10" }).discord?.eventAmount).toBe(10);
    expect(parseConfig({ ...base, DISCORD_STATUS_EVENT_AMOUNT: "999" }).discord?.eventAmount).toBe(50);
    expect(parseConfig({ ...base, DISCORD_STATUS_EVENT_AMOUNT: "0" }).discord?.eventAmount).toBe(1);
    expect(parseConfig({ ...base, DISCORD_STATUS_EVENT_AMOUNT: "999" }).warnings.some((w) => w.includes("EVENT_AMOUNT"))).toBe(
      true,
    );
  });

  it("clamps the Discord update interval to the safety minimum", () => {
    const config = parseConfig({
      DISCORD_STATUS_ENABLED: "true",
      DISCORD_STATUS_WEBHOOK_URL: "https://discord.com/api/webhooks/1/abc",
      DISCORD_STATUS_UPDATE_INTERVAL: "1",
    });
    expect(config.discord?.updateIntervalSeconds).toBe(MIN_DISCORD_INTERVAL_SECONDS);
  });

  it("warns when the event log will lack player events", () => {
    const config = parseConfig({
      PANEL_ENABLED: "true",
      PANEL_PASSWORD: "secret",
      RESTAPI_ENABLED: "true",
      PLAYER_DETECTION_ENABLED: "false",
    });
    expect(config.warnings.some((w) => w.includes("PLAYER_DETECTION_ENABLED"))).toBe(true);
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
