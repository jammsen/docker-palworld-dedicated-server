import { describe, expect, it } from "vitest";
import { parseServerName } from "../src/palworld/ini.js";

const INI_SAMPLE = `[/Script/Pal.PalGameWorldSettings]
OptionSettings=(Difficulty=None,DayTimeSpeedRate=1.000000,ServerName="jammsen-docker-generated-x7Kf2q",ServerDescription="A server",AdminPassword="secret",PublicPort=8211)
`;

describe("parseServerName", () => {
  it("extracts the effective (randomized) server name from the generated INI", () => {
    expect(parseServerName(INI_SAMPLE)).toBe("jammsen-docker-generated-x7Kf2q");
  });

  it("returns null for missing or empty names", () => {
    expect(parseServerName("OptionSettings=(Difficulty=None)")).toBeNull();
    expect(parseServerName('OptionSettings=(ServerName="")')).toBeNull();
  });
});
