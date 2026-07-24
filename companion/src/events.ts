// Two event logs feed the dashboard and the Discord card, merged at read time:
// - game-events.log: written by the gameserver container (includes/gameevents.sh
//   log_game_event), mounted read-only into the companion
// - companion-events.log: written by the companion itself (panel restart,
//   settings saves, REST up/down transitions)
// Both use the same line format: "<epoch>|<type>[|<detail>[|<detail2>]]".
export type ServerEventType =
  | "join"
  | "leave"
  | "rename"
  | "online"
  | "offline"
  | "starting"
  | "installing"
  | "updating"
  | "updating-validate"
  | "stopping"
  | "restart"
  | "backup"
  | "settings";

/** Which log file an event came from - the file split is the provenance */
export type EventSource = "game" | "companion";

export interface ServerEvent {
  at: number;
  type: ServerEventType;
  name?: string;
  newName?: string;
  source?: EventSource;
}

export const ALL_EVENT_TYPES: ServerEventType[] = [
  "join",
  "leave",
  "rename",
  "online",
  "offline",
  "starting",
  "installing",
  "updating",
  "updating-validate",
  "stopping",
  "restart",
  "backup",
  "settings",
];

export const EVENT_LOG_CAPACITY = 50;

const KNOWN_EVENT_TYPES: ReadonlySet<string> = new Set(ALL_EVENT_TYPES);

// Parse one event-log file: "<epoch>|<type>[|<detail>[|<detail2>]]" per line,
// details carrying player names. Unknown types are ignored so a newer writer
// with more event types cannot break an older companion reading the same file.
export function parseEventLog(content: string, source: EventSource): ServerEvent[] {
  const events: ServerEvent[] = [];
  for (const line of content.split("\n")) {
    const match = /^(\d+)\|([a-z-]+)(?:\|([^|]*))?(?:\|([^|]*))?$/.exec(line.trim());
    if (!match) continue;
    if (!KNOWN_EVENT_TYPES.has(match[2]!)) continue;
    const event: ServerEvent = { at: Number.parseInt(match[1]!, 10) * 1000, type: match[2] as ServerEventType, source };
    if (match[3]) event.name = match[3];
    if (match[4]) event.newName = match[4];
    events.push(event);
  }
  return events;
}

// Serialize an event to the shared line format; timestamps are stored with
// second precision. Field and line separators are stripped from details so
// names can neither break the format nor inject fake event lines (mirrors
// includes/gameevents.sh)
export function formatEventLine(event: ServerEvent): string {
  const sanitize = (value: string) => value.replace(/[|\r\n]/g, "");
  const fields = [String(Math.floor(event.at / 1000)), event.type];
  if (event.name !== undefined || event.newName !== undefined) fields.push(sanitize(event.name ?? ""));
  if (event.newName !== undefined) fields.push(sanitize(event.newName));
  return fields.join("|");
}

// The ONLY events the companion detects itself are REST-API up/down
// transitions - its genuine domain. All player events come from the
// battle-tested shell detector (includes/playerdetection.sh) via the game
// event log; there is deliberately no TypeScript re-implementation of that logic.
export function serverStateEvents(previousUp: boolean, currentUp: boolean, at: number): ServerEvent[] {
  if (previousUp === currentUp) return [];
  return [{ at, type: currentUp ? "online" : "offline" }];
}

export function mergeEvents(...logs: ServerEvent[][]): ServerEvent[] {
  // Chronological order across sources: game events are ingested up to one
  // poll interval late, so a plain concatenation could misorder them
  return logs
    .flat()
    .sort((a, b) => a.at - b.at)
    .slice(-EVENT_LOG_CAPACITY);
}
