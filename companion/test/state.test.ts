import { mkdtemp, readFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { describe, expect, it } from "vitest";
import { StateStore } from "../src/state.js";

describe("StateStore", () => {
  it("persists updates and reloads them", async () => {
    const dir = await mkdtemp(join(tmpdir(), "companion-state-"));
    const store = new StateStore(dir);
    await store.load();
    await store.update({ discordMessageId: "msg1", lastRestartAt: 42 });

    const reloaded = new StateStore(dir);
    expect(await reloaded.load()).toEqual({ discordMessageId: "msg1", lastRestartAt: 42 });
  });

  it("returns an empty state when the file is missing or corrupt", async () => {
    const dir = await mkdtemp(join(tmpdir(), "companion-state-"));
    const store = new StateStore(dir);
    expect(await store.load()).toEqual({});
  });

  it("writes atomically without leaving tmp files behind", async () => {
    const dir = await mkdtemp(join(tmpdir(), "companion-state-"));
    const store = new StateStore(dir);
    await store.load();
    await Promise.all([
      store.update({ discordMessageId: "a" }),
      store.update({ lastRestartAt: 1 }),
      store.update({ sessionSecret: "s" }),
    ]);
    const raw = JSON.parse(await readFile(join(dir, "state.json"), "utf8"));
    expect(raw).toEqual({ discordMessageId: "a", lastRestartAt: 1, sessionSecret: "s" });
  });
});
