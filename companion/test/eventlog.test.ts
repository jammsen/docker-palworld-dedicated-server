import { mkdtemp, readFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { describe, expect, it } from "vitest";
import { EventLogWriter } from "../src/eventlog.js";
import { parseEventLog } from "../src/events.js";

describe("EventLogWriter", () => {
  it("appends events in the shared line format, creating the directory", async () => {
    const dir = await mkdtemp(join(tmpdir(), "companion-eventlog-"));
    const filePath = join(dir, "nested", "companion-events.log");
    const writer = new EventLogWriter(filePath);
    await writer.append({ at: 1_752_000_000_000, type: "restart" });
    await writer.append({ at: 1_752_000_060_000, type: "settings" });
    expect(parseEventLog(await readFile(filePath, "utf8"), "companion")).toEqual([
      { at: 1752000000000, type: "restart", source: "companion" },
      { at: 1752000060000, type: "settings", source: "companion" },
    ]);
  });

  it("trims the file to the last 100 lines once it exceeds 200", async () => {
    const dir = await mkdtemp(join(tmpdir(), "companion-eventlog-"));
    const filePath = join(dir, "companion-events.log");
    const writer = new EventLogWriter(filePath);
    // Concurrent appends must serialize - fire them all without awaiting in between
    await Promise.all(
      Array.from({ length: 201 }, (_, i) => writer.append({ at: i * 1000, type: "online" })),
    );
    const lines = (await readFile(filePath, "utf8")).split("\n").filter((line) => line.length > 0);
    expect(lines).toHaveLength(100);
    expect(lines.at(-1)).toBe("200|online");
  });
});
