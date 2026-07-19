import { log } from "../logger.js";
import type { EmbedPayload, StatusTransport } from "./transport.js";

export interface WebhookTransportOptions {
  webhookUrl: string;
  getMessageId: () => string | undefined;
  setMessageId: (id: string | undefined) => Promise<void>;
  fetchFn?: typeof fetch;
}

// Publishes ONE message via the webhook, then edits it in place:
//   first publish  -> POST {webhook}?wait=true (response contains the message id)
//   thereafter     -> PATCH {webhook}/messages/{id}
//   message deleted (404) -> forget the id and re-post
//   rate limited (429)    -> log and skip; the next tick tries again
export class WebhookTransport implements StatusTransport {
  private readonly fetchFn: typeof fetch;

  constructor(private readonly options: WebhookTransportOptions) {
    this.fetchFn = options.fetchFn ?? fetch;
  }

  async publish(payload: EmbedPayload): Promise<void> {
    const messageId = this.options.getMessageId();
    if (messageId) {
      const response = await this.request(`${this.options.webhookUrl}/messages/${messageId}`, "PATCH", payload);
      if (response === "not-found") {
        log.warn(">>> Discord status message was deleted - posting a new one");
        await this.options.setMessageId(undefined);
        await this.createMessage(payload);
      }
      return;
    }
    await this.createMessage(payload);
  }

  private async createMessage(payload: EmbedPayload): Promise<void> {
    const response = await this.fetchFn(`${this.options.webhookUrl}?wait=true`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
      signal: AbortSignal.timeout(10_000),
    });
    if (response.status === 429) {
      this.logRateLimit(response);
      return;
    }
    if (!response.ok) {
      throw new Error(`Discord webhook POST failed (HTTP ${response.status})`);
    }
    const message = (await response.json()) as { id?: string };
    if (message.id) {
      await this.options.setMessageId(message.id);
      log.success(`>>> Discord status card created (message id ${message.id})`);
    }
  }

  private async request(url: string, method: string, payload: EmbedPayload): Promise<"ok" | "not-found"> {
    const response = await this.fetchFn(url, {
      method,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
      signal: AbortSignal.timeout(10_000),
    });
    if (response.status === 404) return "not-found";
    if (response.status === 429) {
      this.logRateLimit(response);
      return "ok";
    }
    if (!response.ok) {
      throw new Error(`Discord webhook ${method} failed (HTTP ${response.status})`);
    }
    return "ok";
  }

  private logRateLimit(response: Response): void {
    const retryAfter = response.headers.get("retry-after") ?? "unknown";
    log.warn(`>>> Discord webhook rate limited (retry-after: ${retryAfter}s) - skipping this update`);
  }
}
