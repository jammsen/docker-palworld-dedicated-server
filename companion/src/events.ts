// online/offline are detected by the companion itself (REST reachability);
// the shell-emitted types come from includes/companion.sh log_companion_event
// via ${GAME_ROOT}/companion/events.log
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

export interface ServerEvent {
  at: number;
  type: ServerEventType;
  name?: string;
  newName?: string;
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

const SHELL_EVENT_TYPES: ReadonlySet<string> = new Set([
  "starting",
  "installing",
  "updating",
  "updating-validate",
  "stopping",
  "restart",
  "backup",
  "settings",
  // Player events emitted by includes/playerdetection.sh - its 15s poll is the
  // reliable observer; the companion's own diff is only a fallback
  "join",
  "leave",
  "rename",
]);

// Parse the shell-written event file: "<epoch>|<type>[|<detail>[|<detail2>]]"
// per line, details carrying player names. Unknown types are ignored so a
// newer image with more event types cannot break an older companion reading
// the same volume.
export function parseShellEvents(content: string): ServerEvent[] {
  const events: ServerEvent[] = [];
  for (const line of content.split("\n")) {
    const match = /^(\d+)\|([a-z-]+)(?:\|([^|]*))?(?:\|([^|]*))?$/.exec(line.trim());
    if (!match) continue;
    if (!SHELL_EVENT_TYPES.has(match[2]!)) continue;
    const event: ServerEvent = { at: Number.parseInt(match[1]!, 10) * 1000, type: match[2] as ServerEventType };
    if (match[3]) event.name = match[3];
    if (match[4]) event.newName = match[4];
    events.push(event);
  }
  return events;
}

export function eventKey(event: ServerEvent): string {
  return `${event.at}|${event.type}|${event.name ?? ""}`;
}

// The ONLY events the companion detects itself are REST-API up/down
// transitions - its genuine domain. All player events come from the
// battle-tested shell detector (includes/playerdetection.sh) via the event
// file; there is deliberately no TypeScript re-implementation of that logic.
export function serverStateEvents(previousUp: boolean, currentUp: boolean, at: number): ServerEvent[] {
  if (previousUp === currentUp) return [];
  return [{ at, type: currentUp ? "online" : "offline" }];
}

export function appendEvents(log: ServerEvent[], events: ServerEvent[]): ServerEvent[] {
  if (events.length === 0) return log;
  // Chronological order: shell events are ingested up to one poll interval
  // late, so a plain append could place them after newer live events
  return [...log, ...events].sort((a, b) => a.at - b.at).slice(-EVENT_LOG_CAPACITY);
}
