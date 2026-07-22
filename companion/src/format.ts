// Shared value formatters used by both the Discord card and the web panel

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

/** UTC timestamp for display: "HH:MM:SS" (time) or "YYYY-MM-DD HH:MM:SS" (datetime) */
export function formatUtcTimestamp(epochMs: number, style: "time" | "datetime"): string {
  const iso = new Date(epochMs).toISOString().replace("T", " ");
  return style === "time" ? iso.slice(11, 19) : iso.slice(0, 19);
}
