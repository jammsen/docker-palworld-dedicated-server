import { mkdtemp, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { describe, expect, it } from "vitest";
import { parseConfig } from "../src/config.js";
import { MetricsCollector } from "../src/metrics/collector.js";
import { PalworldClient } from "../src/palworld/client.js";
import { StateStore } from "../src/state.js";
import { HostProcMetricsSource } from "../src/sys/metrics-source.js";

describe("refreshEventsOnly (SIGTERM path)", () => {
  it("picks up the gameserver's 'stopping' event without touching the game REST API", async () => {
    const gameRoot = await mkdtemp(join(tmpdir(), "companion-shutdown-"));
    const config = parseConfig({ GAME_ROOT: gameRoot });
    const state = new StateStore(config.dataDir);
    await state.load();
    // A fetch stub that throws proves the REST API is never called
    // (RESTAPI_ENABLED is unset, so collect() must not go near it either)
    const client = new PalworldClient(config.restapi, () => {
      throw new Error("REST API must not be called during shutdown refresh");
    });
    const collector = new MetricsCollector(config, client, state, new HostProcMetricsSource());
    await collector.collect();

    // The gameserver writes its 'stopping' marker moments before our SIGTERM
    await writeFile(config.gameEventsFile, `${Math.floor(Date.now() / 1000)}|stopping\n`);

    const snapshot = await collector.refreshEventsOnly();
    expect(snapshot?.events.map((e) => [e.type, e.source])).toEqual([["stopping", "game"]]);
    // The log files are the event store - nothing event-shaped in state.json
    expect(state.get()).not.toHaveProperty("events");
  });
});
