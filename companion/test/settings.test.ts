import { mkdtemp, readFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { describe, expect, it } from "vitest";
import { settingsByKey, validateSettingValue } from "../src/settings/schema.js";
import { SettingsStore } from "../src/settings/store.js";

async function makeStore(env: Record<string, string> = {}) {
  const dir = await mkdtemp(join(tmpdir(), "companion-settings-"));
  return { store: new SettingsStore(dir, env), dir };
}

describe("validateSettingValue", () => {
  it("validates floats with bounds", () => {
    const spec = settingsByKey.get("EXP_RATE")!;
    expect(validateSettingValue(spec, "2.5").ok).toBe(true);
    expect(validateSettingValue(spec, "0").ok).toBe(false);
    expect(validateSettingValue(spec, "999").ok).toBe(false);
    expect(validateSettingValue(spec, "abc").ok).toBe(false);
  });

  it("validates ints, bools and enums", () => {
    expect(validateSettingValue(settingsByKey.get("MAX_PLAYERS")!, "64").ok).toBe(true);
    expect(validateSettingValue(settingsByKey.get("MAX_PLAYERS")!, "500").ok).toBe(false);
    expect(validateSettingValue(settingsByKey.get("IS_PVP")!, "true").ok).toBe(true);
    expect(validateSettingValue(settingsByKey.get("IS_PVP")!, "yes").ok).toBe(false);
    expect(validateSettingValue(settingsByKey.get("DEATH_PENALTY")!, "ItemAndEquipment").ok).toBe(true);
    expect(validateSettingValue(settingsByKey.get("DEATH_PENALTY")!, "Everything").ok).toBe(false);
  });

  it("rejects strings with line breaks (override file safety)", () => {
    const spec = settingsByKey.get("SERVER_DESCRIPTION")!;
    expect(validateSettingValue(spec, "nice server").ok).toBe(true);
    expect(validateSettingValue(spec, "evil\nNEW_KEY=1").ok).toBe(false);
  });
});

describe("SettingsStore", () => {
  it("writes only differing values as overrides and round-trips them", async () => {
    const { store } = await makeStore({ EXP_RATE: "2.000000" });
    const changes = await store.applySubmission(
      new Map([
        ["EXP_RATE", "2.0"], // equals env value after normalization -> no override
        ["PAL_CAPTURE_RATE", "3.0"], // differs from default -> override
      ]),
    );
    expect(changes).toBe(1);
    const overrides = await store.readOverrides();
    expect(overrides.get("PAL_CAPTURE_RATE")).toBe("3.000000");
    expect(overrides.has("EXP_RATE")).toBe(false);
  });

  it("reports provenance default / env / override", async () => {
    const { store } = await makeStore({ EXP_RATE: "2.000000" });
    await store.applySubmission(new Map([["PAL_CAPTURE_RATE", "3.0"]]));
    const effective = await store.effectiveSettings();
    const byKey = new Map(effective.map((s) => [s.spec.key, s]));
    expect(byKey.get("EXP_RATE")!.provenance).toBe("env");
    expect(byKey.get("PAL_CAPTURE_RATE")!.provenance).toBe("override");
    expect(byKey.get("WORK_SPEED_RATE")!.provenance).toBe("default");
  });

  it("removes an override when the value returns to the env value", async () => {
    const { store } = await makeStore();
    await store.applySubmission(new Map([["MAX_PLAYERS", "64"]]));
    expect((await store.readOverrides()).size).toBe(1);
    await store.applySubmission(new Map([["MAX_PLAYERS", "32"]]));
    expect((await store.readOverrides()).size).toBe(0);
  });

  it("resets single and all overrides", async () => {
    const { store } = await makeStore();
    await store.applySubmission(
      new Map([
        ["MAX_PLAYERS", "64"],
        ["IS_PVP", "true"],
      ]),
    );
    await store.resetOverride("MAX_PLAYERS");
    expect([...(await store.readOverrides()).keys()]).toEqual(["IS_PVP"]);
    await store.resetAllOverrides();
    expect((await store.readOverrides()).size).toBe(0);
  });

  it("never writes excluded keys", async () => {
    const { store } = await makeStore();
    const changes = await store.applySubmission(
      new Map([
        ["ADMIN_PASSWORD", "hacked"],
        ["RESTAPI_ENABLED", "false"],
      ]),
    );
    expect(changes).toBe(0);
    expect((await store.readOverrides()).size).toBe(0);
  });

  it("writes a header and sorted KEY=value lines parseable by bash", async () => {
    const { store, dir } = await makeStore();
    await store.applySubmission(
      new Map([
        ["MAX_PLAYERS", "64"],
        ["EXP_RATE", "5"],
      ]),
    );
    const content = await readFile(join(dir, "settings-overrides.env"), "utf8");
    expect(content.startsWith("# Managed by the palworld-companion web panel")).toBe(true);
    expect(content).toContain("EXP_RATE=5.000000\nMAX_PLAYERS=64\n");
  });

  it("exports effective settings without excluded keys (no template)", async () => {
    const { store } = await makeStore({ EXP_RATE: "2.000000" });
    const exported = await store.exportEnv();
    expect(exported).toContain("EXP_RATE=2.000000");
    expect(exported).not.toContain("ADMIN_PASSWORD");
  });

  it("template export preserves order, comments, quoting and secret placeholders", async () => {
    const { store } = await makeStore({ EXP_RATE: "2.000000" });
    await store.applySubmission(new Map([["MAX_PLAYERS", "64"]]));
    const template = [
      "# Backup-settings",
      "BACKUP_ENABLED=true",
      "# PalWorldSettings.ini settings",
      "EXP_RATE=1.000000",
      "MAX_PLAYERS=32",
      'SERVER_NAME="my server"',
      "ADMIN_PASSWORD=adminPasswordHere",
      "",
    ].join("\n");
    const exported = await store.exportEnv(template);
    const lines = exported.split("\n").filter((line) => !line.startsWith("# Effective") && !line.startsWith("# Generated") && !line.startsWith("# Gameserver") && !line.startsWith("# all other"));
    expect(lines).toEqual([
      "# Backup-settings",
      "BACKUP_ENABLED=true", // non-gameserver key: template line kept verbatim
      "# PalWorldSettings.ini settings",
      "EXP_RATE=2.000000", // env value applied
      "MAX_PLAYERS=64", // panel override applied
      'SERVER_NAME="jammsen-docker-generated-###RANDOM###"', // quoting style preserved
      "ADMIN_PASSWORD=adminPasswordHere", // secret: template placeholder, never the real value
      "",
    ]);
  });
});
