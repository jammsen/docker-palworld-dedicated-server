import { mkdtemp, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { describe, expect, it } from "vitest";
import { parseConfig } from "../src/config.js";
import { MetricsCollector } from "../src/metrics/collector.js";
import { PalworldClient } from "../src/palworld/client.js";
import { StateStore } from "../src/state.js";

describe("refreshEventsOnly (SIGTERM path)", () => {
  it("ingests the shell 'stopping' event without touching the game REST API", async () => {
    const gameRoot = await mkdtemp(join(tmpdir(), "companion-shutdown-"));
    const config = parseConfig({ GAME_ROOT: gameRoot });
    const state = new StateStore(config.dataDir);
    await state.load();
    // A fetch stub that throws proves the REST API is never called
    const client = new PalworldClient(config.restapi, () => {
      throw new Error("REST API must not be called during shutdown refresh");
    });
    const collector = new MetricsCollector(config, client, state);

    await writeFile(join(config.dataDir, "events.log"), `${Math.floor(Date.now() / 1000)}|stopping\n`).catch(async () => {
      const { mkdir } = await import("node:fs/promises");
      await mkdir(config.dataDir, { recursive: true });
      await writeFile(join(config.dataDir, "events.log"), `${Math.floor(Date.now() / 1000)}|stopping\n`);
    });

    await collector.refreshEventsOnly();
    expect(state.get().events?.map((e) => e.type)).toEqual(["stopping"]);
  });
});
