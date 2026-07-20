// The /players userId is platform-prefixed, e.g. "steam_76561..." or "xbox_...".
// Parse generically so future crossplay prefixes (PS5, Mac, ...) render too.
const PLATFORM_LABELS: Record<string, string> = {
  steam: "Steam",
  xbox: "Xbox",
  ps5: "PS5",
  mac: "Mac",
};

export function platformFromUserId(userId: string): string {
  const prefix = userId.split("_")[0]?.toLowerCase() ?? "";
  if (!prefix || prefix === userId.toLowerCase()) return "?";
  return PLATFORM_LABELS[prefix] ?? prefix.charAt(0).toUpperCase() + prefix.slice(1);
}

// Colored-square markers for the Discord card, loosely matching brand colors.
// Users can replace them with real platform-logo emojis uploaded to their own
// Discord server via DISCORD_STATUS_EMOJI_* (value format: <:name:id>).
const PLATFORM_EMOJI: Record<string, string> = {
  steam: "🟦",
  xbox: "🟩",
  ps5: "🔹",
  mac: "⚪",
};

export type PlatformEmojiOverrides = Partial<Record<string, string>>;

export function platformEmojiFromUserId(userId: string, overrides: PlatformEmojiOverrides = {}): string {
  const prefix = userId.split("_")[0]?.toLowerCase() ?? "";
  return overrides[prefix] ?? PLATFORM_EMOJI[prefix] ?? "▫️";
}
