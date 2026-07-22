import { describe, expect, it } from "vitest";
import { appendEvents, EVENT_LOG_CAPACITY, parseShellEvents, serverStateEvents, type ServerEvent } from "../src/events.js";

const NOW = 1_752_000_000_000;

// Player join/leave/rename detection deliberately has NO TypeScript
// implementation - the shell player-detection loop is the single source
// (see parseShellEvents below); the companion only observes REST up/down.
describe("serverStateEvents", () => {
  it("detects server up/down transitions", () => {
    expect(serverStateEvents(false, true, NOW)).toEqual([{ at: NOW, type: "online" }]);
    expect(serverStateEvents(true, false, NOW)).toEqual([{ at: NOW, type: "offline" }]);
    expect(serverStateEvents(true, true, NOW)).toEqual([]);
    expect(serverStateEvents(false, false, NOW)).toEqual([]);
  });
});

describe("parseShellEvents", () => {
  it("parses epoch|type lines from the shell event file", () => {
    const content = "1752000000|starting\n1752000060|updating\n1752000090|updating-validate\n1752000120|backup\n";
    expect(parseShellEvents(content)).toEqual([
      { at: 1752000000000, type: "starting" },
      { at: 1752000060000, type: "updating" },
      { at: 1752000090000, type: "updating-validate" },
      { at: 1752000120000, type: "backup" },
    ]);
  });

  it("ignores malformed lines and unknown types", () => {
    const content = "garbage\n1752000000|unknown-type\n|starting\n1752000001|starting\n";
    expect(parseShellEvents(content)).toEqual([{ at: 1752000001000, type: "starting" }]);
  });

  it("parses player events with names from the shell player detection", () => {
    const content = [
      "1752000000|join|Selfcut",
      '1752000010|rename|Selfcut|Selfcut,,,,.-$%!',
      "1752000020|leave|Selfcut,,,,.-$%!",
    ].join("\n");
    expect(parseShellEvents(content)).toEqual([
      { at: 1752000000000, type: "join", name: "Selfcut" },
      { at: 1752000010000, type: "rename", name: "Selfcut", newName: "Selfcut,,,,.-$%!" },
      { at: 1752000020000, type: "leave", name: "Selfcut,,,,.-$%!" },
    ]);
  });
});

describe("appendEvents", () => {
  it("keeps the merged log in chronological order", () => {
    const log: ServerEvent[] = [{ at: 100, type: "online" }];
    // Shell event ingested late, with an older timestamp than the live event
    const merged = appendEvents(log, [
      { at: 150, type: "join", name: "a" },
      { at: 120, type: "starting" },
    ]);
    expect(merged.map((e) => e.at)).toEqual([100, 120, 150]);
  });

  it("caps the log at the ring-buffer capacity, keeping the newest", () => {
    const old: ServerEvent[] = Array.from({ length: EVENT_LOG_CAPACITY }, (_, i) => ({ at: i, type: "join", name: `p${i}` }));
    const appended = appendEvents(old, [{ at: 999, type: "leave", name: "new" }]);
    expect(appended).toHaveLength(EVENT_LOG_CAPACITY);
    expect(appended.at(-1)).toEqual({ at: 999, type: "leave", name: "new" });
    expect(appended[0]?.at).toBe(1);
  });
});
