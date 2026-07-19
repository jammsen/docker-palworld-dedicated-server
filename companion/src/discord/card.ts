import type { StatusSnapshot } from "../metrics/collector.js";
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

function cpuFields(corePercents: number[]): DiscordEmbedField[] {
  if (corePercents.length === 0) return [];
  const lines = corePercents.map(
    (percent, index) => `Core ${String(index + 1).padStart(2, " ")} [${bar(percent, 10)}] ${String(percent).padStart(3, " ")}%`,
  );
  const fields: DiscordEmbedField[] = [];
  for (let start = 0; start < lines.length; start += CORES_PER_FIELD) {
    if (fields.length === 2) {
      // Beyond 80 cores: collapse the rest into an average to stay inside embed budgets
      const rest = corePercents.slice(start);
      const avg = Math.round(rest.reduce((sum, v) => sum + v, 0) / rest.length);
      fields.push({
        name: "CPU (rest)",
        value: `\`\`\`${rest.length} more cores, avg ${avg}%\`\`\``,
      });
      break;
    }
    const chunk = lines.slice(start, start + CORES_PER_FIELD);
    fields.push({
      name: corePercents.length <= CORES_PER_FIELD ? "CPU Core Breakdown" : `CPU Cores ${start + 1}-${start + chunk.length}`,
      value: `\`\`\`${chunk.join("\n")}\`\`\``,
    });
  }
  return fields;
}

function playersField(snapshot: StatusSnapshot): DiscordEmbedField | null {
  if (snapshot.players.length === 0) return null;
  const lines: string[] = [];
  let used = 0;
  let shown = 0;
  for (const player of snapshot.players) {
    const line = `${sanitizeName(player.name)} (Lv. ${player.level})`;
    if (used + line.length + 1 > PLAYER_LIST_BUDGET) break;
    lines.push(line);
    used += line.length + 1;
    shown += 1;
  }
  const remaining = snapshot.players.length - shown;
  if (remaining > 0) lines.push(`…and ${remaining} more`);
  return {
    name: `Online (${snapshot.players.length})`,
    value: `\`\`\`${lines.join("\n")}\`\`\``,
  };
}

export function buildStatusCard(snapshot: StatusSnapshot | null, state: CardState, serverName: string): EmbedPayload {
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
    const pings = snapshot.players.map((p) => p.ping).filter((p) => Number.isFinite(p) && p >= 0);
    const avgPing = pings.length > 0 ? `${Math.round(pings.reduce((s, p) => s + p, 0) / pings.length)}ms` : "n/a";

    fields.push(
      { name: "⏱️ Uptime", value: `\`${formatDuration(game.uptime)}\``, inline: true },
      { name: "👥 Population", value: `\`${game.currentplayernum} / ${game.maxplayernum}\``, inline: true },
      { name: "📡 Latency", value: `\`${avgPing}\``, inline: true },
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

    const players = playersField(snapshot);
    if (players) fields.push(players);
  }

  // Hard guards for Discord embed limits (25 fields / 1024 chars per value / 6000 total)
  const limitedFields = fields.slice(0, 25).map((field) => ({
    ...field,
    value: field.value.length > MAX_FIELD_CHARS ? `${field.value.slice(0, MAX_FIELD_CHARS - 4)}\`\`\`` : field.value,
  }));

  return {
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
