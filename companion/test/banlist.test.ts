import { describe, expect, it } from "vitest";
import { parseBanlist } from "../src/palworld/banlist.js";

describe("parseBanlist", () => {
  it("extracts the userid from 'userid,playerUID' lines", () => {
    const entries = parseBanlist("steam_76561197961348531,4DCC09FB00000000000000000000000000\n");
    expect(entries).toEqual([
      {
        userid: "steam_76561197961348531",
        raw: "steam_76561197961348531,4DCC09FB00000000000000000000000000",
      },
    ]);
    // The extracted userid must pass the moderation-action validation regex
    expect(/^[A-Za-z0-9_]+$/.test(entries[0]!.userid)).toBe(true);
  });

  it("handles plain userid lines without a playerUID", () => {
    expect(parseBanlist("steam_123\n")).toEqual([{ userid: "steam_123", raw: "steam_123" }]);
  });

  it("skips empty and whitespace-only lines", () => {
    expect(parseBanlist("\n  \nsteam_1,abc\n\n")).toHaveLength(1);
  });
});
