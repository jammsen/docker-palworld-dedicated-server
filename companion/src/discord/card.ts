import type { ServerEvent } from "../events.js";
import type { StatusSnapshot } from "../metrics/collector.js";
import { platformEmojiFromUserId, type PlatformEmojiOverrides } from "../palworld/platform.js";
import type { DiscordEmbedField, EmbedPayload } from "./transport.js";

const COLOR_ONLINE = 3066993; // green
const COLOR_STARTING = 15844367; // yellow
const COLOR_OFFLINE = 15158332; // red

const MAX_FIELD_CHARS = 1024;
const CORES_PER_FIELD = 40;
const PLAYER_LIST_BUDGET = 950;

export type CardState = "online" | "starting" | "offline";

function bar(percent: number, width: number): string {
  const filled = Math.round((Math.min(100, Math.max(0, percent)) / 100) * width);
  return "█".repeat(filled) + "░".repeat(width - filled);
}

export function formatDuration(totalSeconds: number): string {
  const days = Math.floor(totalSeconds / 86_400);
  const hours = Math.floor((totalSeconds % 86_400) / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  if (days > 0) return `${days}d ${hours}h ${minutes}m`;
  if (hours > 0) return `${hours}h ${minutes}m`;
  return `${minutes}m`;
}

export function formatGiB(bytes: number): string {
  return `${(bytes / 1024 ** 3).toFixed(1)} GiB`;
}

// Strip control characters and embed-breaking markdown from player names
// (same rationale as the sanitization in includes/playerdetection.sh)
export function sanitizeName(name: string): string {
  // eslint-disable-next-line no-control-regex
  return name.replace(/[\u0000-\u001F\u007F`]/g, "").slice(0, 32);
}

// Two INLINE fields render side by side on desktop (two cores per visual row,
// using the embed's full ~520px width) and stack full-width on mobile - a
// single wide code block would wrap and break the bars on narrow clients.
function cpuFields(corePercents: number[]): DiscordEmbedField[] {
  if (corePercents.length === 0) return [];
  const lines = corePercents.map(
    (percent, index) => `C${String(index + 1).padStart(2, "0")} ${bar(percent, 10)} ${String(percent).padStart(3, " ")}%`,
  );

  // Beyond 2x CORES_PER_FIELD: collapse the rest into an average to stay inside budgets
  const shown = lines.slice(0, CORES_PER_FIELD * 2);
  const rest = corePercents.slice(CORES_PER_FIELD * 2);
  // Row-major reading order: row 1 is C01|C02, row 2 is C03|C04 ... - humans
  // scan left-to-right, and with SMT siblings numbered adjacently each visual
  // row corresponds to one physical core
  const columns = [shown.filter((_, i) => i % 2 === 0), shown.filter((_, i) => i % 2 === 1)].filter(
    (column) => column.length > 0,
  );

  const fields: DiscordEmbedField[] = columns.map((column, index) => ({
    name: index === 0 ? "⚙️ CPU Core Breakdown" : "​",
    value: `\`\`\`${column.join("\n")}\`\`\``,
    inline: true,
  }));
  if (rest.length > 0) {
    const avg = Math.round(rest.reduce((sum, v) => sum + v, 0) / rest.length);
    fields.push({ name: "CPU (rest)", value: `\`\`\`${rest.length} more cores, avg ${avg}%\`\`\`` });
  }
  return fields;
}

const DEFAULT_EVENT_DISPLAY_COUNT = 25;

const EVENT_EMOJI: Record<string, string> = {
  join: "🟢",
  leave: "🔴",
  rename: "✏️",
  online: "✅",
  offline: "⛔",
  starting: "⏳",
  installing: "📦",
  updating: "⬇️",
  "updating-validate": "🛠️",
  stopping: "🛑",
  restart: "🔄",
  backup: "💾",
  settings: "⚙️",
};

const EVENT_LABELS: Record<string, string> = {
  online: "Server online",
  offline: "Server offline",
  starting: "Starting gameserver",
  installing: "Installing gameserver via SteamCMD",
  updating: "SteamCMD - updating gameserver files",
  "updating-validate": "SteamCMD - updating and validating gameserver files",
  stopping: "Stopping server",
  restart: "Automatic restart triggered",
  backup: "Backup created",
  settings: "Settings changed via web panel",
};

function renderEventLine(event: ServerEvent, eventEmoji: Partial<Record<string, string>>): string {
  const time = `<t:${Math.floor(event.at / 1000)}:t>`;
  const emoji = eventEmoji[event.type] ?? EVENT_EMOJI[event.type] ?? "▫️";
  // Emoji first: Discord's font has proportional digits, so timestamps
  // differ in width - leading emojis keep the icon column perfectly straight
  switch (event.type) {
    case "join":
      return `${emoji} ${time} \`${sanitizeName(event.name ?? "?")}\` joined`;
    case "leave":
      return `${emoji} ${time} \`${sanitizeName(event.name ?? "?")}\` left`;
    case "rename":
      return `${emoji} ${time} \`${sanitizeName(event.name ?? "?")}\` is now \`${sanitizeName(event.newName ?? "?")}\``;
    default:
      return `${emoji} ${time} ${EVENT_LABELS[event.type] ?? event.type}`;
  }
}

// Custom emoji tokens cost ~44 RAW characters each (Discord counts markdown,
// not rendered glyphs), so a full log no longer fits one 1024-char field.
// The log spans up to MAX_EVENT_FIELDS fields instead; continuation fields
// carry a zero-width-space name so they render as one seamless block.
const MAX_EVENT_FIELDS = 3;

function eventsFields(
  snapshot: StatusSnapshot,
  maxEvents: number,
  eventEmoji: Partial<Record<string, string>>,
): DiscordEmbedField[] {
  if (snapshot.events.length === 0) return [];
  const source = snapshot.events.slice(-maxEvents).reverse();

  const fields: DiscordEmbedField[] = [];
  let lines: string[] = [];
  let used = 0;
  let shown = 0;
  const flush = () => {
    if (lines.length === 0) return;
    fields.push({
      name: fields.length === 0 ? `📜 Last events (${source.length})` : "​",
      value: lines.join("\n"),
    });
    lines = [];
    used = 0;
  };

  for (const event of source) {
    const line = renderEventLine(event, eventEmoji);
    if (used + line.length + 1 > MAX_FIELD_CHARS - 30) {
      if (fields.length === MAX_EVENT_FIELDS - 1) {
        lines.push(`…and ${source.length - shown} more`);
        break;
      }
      flush();
    }
    lines.push(line);
    used += line.length + 1;
    shown += 1;
  }
  flush();
  return fields;
}

function playersField(snapshot: StatusSnapshot, platformEmoji: PlatformEmojiOverrides): DiscordEmbedField | null {
  if (snapshot.players.length === 0) return null;
  const lines: string[] = [];
  let used = 0;
  let shown = 0;
  for (const player of snapshot.players) {
    // Platform emoji outside the inline code (emojis don't render inside code),
    // name inside backticks so stray markdown in names cannot break the embed
    const line = `${platformEmojiFromUserId(player.userId, platformEmoji)} \`${sanitizeName(player.name)}\` (Lv. ${player.level})`;
    if (used + line.length + 1 > PLAYER_LIST_BUDGET) break;
    lines.push(line);
    used += line.length + 1;
    shown += 1;
  }
  const remaining = snapshot.players.length - shown;
  if (remaining > 0) lines.push(`…and ${remaining} more`);
  return {
    name: `Online (${snapshot.players.length})`,
    value: lines.join("\n"),
  };
}

export interface CardOptions {
  platformEmoji?: PlatformEmojiOverrides;
  eventEmoji?: Partial<Record<string, string>>;
  eventAmount?: number;
}

export function buildStatusCard(
  snapshot: StatusSnapshot | null,
  state: CardState,
  serverName: string,
  options: CardOptions = {},
): EmbedPayload {
  const platformEmoji = options.platformEmoji ?? {};
  const eventEmoji = options.eventEmoji ?? {};
  const eventAmount = options.eventAmount ?? DEFAULT_EVENT_DISPLAY_COUNT;
  const fields: DiscordEmbedField[] = [];
  let color = COLOR_OFFLINE;
  let description: string | undefined;

  if (state === "starting") {
    color = COLOR_STARTING;
    description = "⏳ Server is starting…";
  } else if (state === "offline") {
    color = COLOR_OFFLINE;
    description = "🔴 Server is offline";
  } else {
    color = COLOR_ONLINE;
  }

  if (snapshot && state === "online" && snapshot.game) {
    const game = snapshot.game;

    fields.push(
      { name: "⏱️ Uptime", value: `\`${formatDuration(game.uptime)}\``, inline: true },
      { name: "👥 Population", value: `\`${game.currentplayernum} / ${game.maxplayernum}\``, inline: true },
      { name: "⏲️ Frame time", value: `\`${game.serverframetime.toFixed(1)} ms\``, inline: true },
      { name: "⚡ Server FPS", value: `\`${game.serverfps}\``, inline: true },
      {
        name: "💾 RAM Usage",
        value: `\`${formatGiB(snapshot.ram.usedBytes)} / ${formatGiB(snapshot.ram.totalBytes)}\``,
        inline: true,
      },
      { name: "📅 In-game Day", value: `\`${game.days}\``, inline: true },
    );

    fields.push(...cpuFields(snapshot.cpuCorePercents));

    if (snapshot.lastRestartAt !== null) {
      fields.push({
        name: "🔄 Last Restart",
        value: `<t:${Math.floor(snapshot.lastRestartAt / 1000)}:R>`,
      });
    }

    const players = playersField(snapshot, platformEmoji);
    if (players) fields.push(players);
  }

  // The event log renders in EVERY state - it matters most while the server
  // is starting or offline, when users want to see what is happening
  if (snapshot) {
    fields.push(...eventsFields(snapshot, eventAmount, eventEmoji));
  }

  // Hard guards for Discord embed limits (25 fields / 1024 chars per value / 6000 total)
  const limitedFields = fields.slice(0, 25).map((field) => ({
    ...field,
    value: field.value.length > MAX_FIELD_CHARS ? `${field.value.slice(0, MAX_FIELD_CHARS - 4)}\`\`\`` : field.value,
  }));

  const payload: EmbedPayload = {
    embeds: [
      {
        title: `🛡️ ${serverName}`,
        ...(description ? { description } : {}),
        color,
        fields: limitedFields,
        timestamp: new Date().toISOString(),
        footer: { text: "Last updated" },
      },
    ],
  };

  // Total-budget valve: in extreme configs (many cores + full player list +
  // token-heavy event log) drop event continuation fields until we fit.
  // Event continuations are the non-inline ZWSP fields (CPU columns are inline).
  while (embedCharacterCount(payload) > 5900 && limitedFields.at(-1)?.name === "​" && !limitedFields.at(-1)?.inline) {
    limitedFields.pop();
  }
  return payload;
}

// Total character count relevant for Discord's 6000-char embed budget
export function embedCharacterCount(payload: EmbedPayload): number {
  let total = 0;
  for (const embed of payload.embeds) {
    total += embed.title.length + (embed.description?.length ?? 0) + (embed.footer?.text.length ?? 0);
    for (const field of embed.fields) {
      total += field.name.length + field.value.length;
    }
  }
  return total;
}
