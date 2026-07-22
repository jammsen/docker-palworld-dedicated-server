import { describe, expect, it } from "vitest";
import { platformEmojiFromUserId, platformFromUserId } from "../src/palworld/platform.js";

describe("platformFromUserId", () => {
  it("recognizes known platform prefixes", () => {
    expect(platformFromUserId("steam_76561197961348531")).toBe("Steam");
    expect(platformFromUserId("xbox_2535412345678901")).toBe("Xbox");
  });

  it("capitalizes unknown prefixes generically", () => {
    expect(platformFromUserId("epic_abc123")).toBe("Epic");
  });

  it("returns ? when there is no prefix", () => {
    expect(platformFromUserId("76561197961348531")).toBe("?");
    expect(platformFromUserId("")).toBe("?");
  });
});

describe("platformEmojiFromUserId", () => {
  it("uses default colored squares", () => {
    expect(platformEmojiFromUserId("steam_123")).toBe("🟦");
    expect(platformEmojiFromUserId("xbox_123")).toBe("🟩");
    expect(platformEmojiFromUserId("unknown_123")).toBe("▫️");
  });

  it("prefers custom emoji overrides", () => {
    const overrides = { steam: "<:steam:1123581321345589012>" };
    expect(platformEmojiFromUserId("steam_123", overrides)).toBe("<:steam:1123581321345589012>");
    expect(platformEmojiFromUserId("xbox_123", overrides)).toBe("🟩");
  });
});
