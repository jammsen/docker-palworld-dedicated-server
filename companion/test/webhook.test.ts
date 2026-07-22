import { describe, expect, it, vi } from "vitest";
import { WebhookTransport } from "../src/discord/webhook.js";
import type { EmbedPayload } from "../src/discord/transport.js";

const PAYLOAD: EmbedPayload = { embeds: [{ title: "t", color: 0, fields: [] }] };
const URL = "https://discord.example/api/webhooks/1/token";

function jsonResponse(status: number, body: unknown = {}): Response {
  return new Response(JSON.stringify(body), { status });
}

function makeTransport(fetchFn: typeof fetch, initialId?: string) {
  let messageId: string | undefined = initialId;
  const transport = new WebhookTransport({
    webhookUrl: URL,
    getMessageId: () => messageId,
    setMessageId: async (id) => {
      messageId = id;
    },
    fetchFn,
  });
  return { transport, getId: () => messageId };
}

describe("WebhookTransport", () => {
  it("POSTs with ?wait=true on first publish and stores the message id", async () => {
    const fetchFn = vi.fn().mockResolvedValue(jsonResponse(200, { id: "msg123" }));
    const { transport, getId } = makeTransport(fetchFn);

    await transport.publish(PAYLOAD);

    expect(fetchFn).toHaveBeenCalledTimes(1);
    expect(fetchFn.mock.calls[0]![0]).toBe(`${URL}?wait=true`);
    expect(getId()).toBe("msg123");
  });

  it("PATCHes the stored message on subsequent publishes", async () => {
    const fetchFn = vi.fn().mockResolvedValue(jsonResponse(200));
    const { transport } = makeTransport(fetchFn, "msg123");

    await transport.publish(PAYLOAD);

    expect(fetchFn.mock.calls[0]![0]).toBe(`${URL}/messages/msg123`);
    expect((fetchFn.mock.calls[0]![1] as RequestInit).method).toBe("PATCH");
  });

  it("re-posts a new message when the stored one was deleted (404)", async () => {
    const fetchFn = vi
      .fn()
      .mockResolvedValueOnce(jsonResponse(404))
      .mockResolvedValueOnce(jsonResponse(200, { id: "msg456" }));
    const { transport, getId } = makeTransport(fetchFn, "msg123");

    await transport.publish(PAYLOAD);

    expect(fetchFn).toHaveBeenCalledTimes(2);
    expect(fetchFn.mock.calls[1]![0]).toBe(`${URL}?wait=true`);
    expect(getId()).toBe("msg456");
  });

  it("skips the update quietly when rate limited (429)", async () => {
    const fetchFn = vi.fn().mockResolvedValue(jsonResponse(429));
    const { transport, getId } = makeTransport(fetchFn, "msg123");

    await expect(transport.publish(PAYLOAD)).resolves.toBeUndefined();
    expect(getId()).toBe("msg123");
  });

  it("throws on other HTTP errors", async () => {
    const fetchFn = vi.fn().mockResolvedValue(jsonResponse(500));
    const { transport } = makeTransport(fetchFn, "msg123");

    await expect(transport.publish(PAYLOAD)).rejects.toThrow("HTTP 500");
  });
});
