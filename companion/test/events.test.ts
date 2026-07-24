import { describe, expect, it } from "vitest";
import { EVENT_LOG_CAPACITY, formatEventLine, mergeEvents, parseEventLog, serverStateEvents, type ServerEvent } from "../src/events.js";

const NOW = 1_752_000_000_000;

// Player join/leave/rename detection deliberately has NO TypeScript
// implementation - the shell player-detection loop is the single source
// (see parseEventLog below); the companion only observes REST up/down.
describe("serverStateEvents", () => {
  it("detects server up/down transitions", () => {
    expect(serverStateEvents(false, true, NOW)).toEqual([{ at: NOW, type: "online" }]);
    expect(serverStateEvents(true, false, NOW)).toEqual([{ at: NOW, type: "offline" }]);
    expect(serverStateEvents(true, true, NOW)).toEqual([]);
    expect(serverStateEvents(false, false, NOW)).toEqual([]);
  });
});

describe("parseEventLog", () => {
  it("parses epoch|type lines and tags the source file as provenance", () => {
    const content = "1752000000|starting\n1752000060|updating\n1752000090|updating-validate\n1752000120|backup\n";
    expect(parseEventLog(content, "game")).toEqual([
      { at: 1752000000000, type: "starting", source: "game" },
      { at: 1752000060000, type: "updating", source: "game" },
      { at: 1752000090000, type: "updating-validate", source: "game" },
      { at: 1752000120000, type: "backup", source: "game" },
    ]);
  });

  it("ignores malformed lines and unknown types", () => {
    const content = "garbage\n1752000000|unknown-type\n|starting\n1752000001|starting\n";
    expect(parseEventLog(content, "game")).toEqual([{ at: 1752000001000, type: "starting", source: "game" }]);
  });

  it("parses player events with names from the shell player detection", () => {
    const content = [
      "1752000000|join|Selfcut",
      '1752000010|rename|Selfcut|Selfcut,,,,.-$%!',
      "1752000020|leave|Selfcut,,,,.-$%!",
    ].join("\n");
    expect(parseEventLog(content, "game")).toEqual([
      { at: 1752000000000, type: "join", name: "Selfcut", source: "game" },
      { at: 1752000010000, type: "rename", name: "Selfcut", newName: "Selfcut,,,,.-$%!", source: "game" },
      { at: 1752000020000, type: "leave", name: "Selfcut,,,,.-$%!", source: "game" },
    ]);
  });
});

describe("formatEventLine", () => {
  it("round-trips through parseEventLog", () => {
    const events: ServerEvent[] = [
      { at: NOW, type: "restart" },
      { at: NOW, type: "settings" },
      { at: NOW, type: "rename", name: "Old", newName: "New" },
    ];
    const content = events.map((e) => formatEventLine(e)).join("\n");
    expect(parseEventLog(content, "companion")).toEqual(events.map((e) => ({ ...e, source: "companion" })));
  });

  it("stores second precision and strips separators from names", () => {
    expect(formatEventLine({ at: 1752000000999, type: "join", name: "a|b" })).toBe("1752000000|join|ab");
    // Newlines must not survive - a crafted name could otherwise inject a fake event line
    expect(formatEventLine({ at: 1752000000000, type: "join", name: "a\n9999999999|backup" })).toBe(
      "1752000000|join|a9999999999backup",
    );
  });
});

describe("mergeEvents", () => {
  it("merges both logs in chronological order", () => {
    const companion: ServerEvent[] = [{ at: 100, type: "online", source: "companion" }];
    // Game events are ingested late, with older timestamps than the live event
    const game: ServerEvent[] = [
      { at: 150, type: "join", name: "a", source: "game" },
      { at: 120, type: "starting", source: "game" },
    ];
    expect(mergeEvents(game, companion).map((e) => e.at)).toEqual([100, 120, 150]);
  });

  it("caps the merged log at the display capacity, keeping the newest", () => {
    const old: ServerEvent[] = Array.from({ length: EVENT_LOG_CAPACITY }, (_, i) => ({ at: i, type: "join", name: `p${i}` }));
    const merged = mergeEvents(old, [{ at: 999, type: "leave", name: "new" }]);
    expect(merged).toHaveLength(EVENT_LOG_CAPACITY);
    expect(merged.at(-1)).toEqual({ at: 999, type: "leave", name: "new" });
    expect(merged[0]?.at).toBe(1);
  });
});
