export interface DiscordEmbedField {
  name: string;
  value: string;
  inline?: boolean;
}

export interface DiscordEmbed {
  title: string;
  description?: string;
  color: number;
  fields: DiscordEmbedField[];
  timestamp?: string;
  footer?: { text: string };
}

export interface EmbedPayload {
  embeds: DiscordEmbed[];
}

// Transport seam: webhook today, bot account (channel messages + bot token) later.
// Implementations own create-or-edit semantics so callers just publish.
export interface StatusTransport {
  publish(payload: EmbedPayload): Promise<void>;
}
