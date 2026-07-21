import type { RestApiConfig } from "../config.js";

export interface GameMetrics {
  serverfps: number;
  currentplayernum: number;
  serverframetime: number;
  maxplayernum: number;
  uptime: number;
  days: number;
  basecampnum?: number;
}

export interface GamePlayer {
  name: string;
  accountName: string;
  playerId: string;
  userId: string;
  ip: string;
  ping: number;
  location_x: number;
  location_y: number;
  level: number;
  building_count: number;
}

export interface GameInfo {
  version: string;
  servername: string;
  description: string;
}

export class PalworldRestError extends Error {
  constructor(
    public readonly endpoint: string,
    public readonly status: number,
  ) {
    super(`REST API ${endpoint} failed (HTTP ${status})`);
  }
}

// Thin typed client for the game's local REST API - the Node counterpart of includes/restapi.sh
export class PalworldClient {
  private readonly baseUrl: string;
  private readonly authHeader: string;
  private readonly timeoutMs: number;

  constructor(
    restapi: RestApiConfig,
    private readonly fetchFn: typeof fetch = fetch,
  ) {
    this.baseUrl = `http://127.0.0.1:${restapi.port}/v1/api/`;
    this.authHeader = `Basic ${Buffer.from(`admin:${restapi.adminPassword}`).toString("base64")}`;
    this.timeoutMs = restapi.timeoutSeconds * 1000;
  }

  private async request(endpoint: string, init: { method?: "GET" | "POST"; body?: unknown } = {}): Promise<Response> {
    const method = init.method ?? (init.body === undefined ? "GET" : "POST");
    const response = await this.fetchFn(this.baseUrl + endpoint, {
      method,
      headers: {
        Authorization: this.authHeader,
        Accept: "application/json",
        ...(init.body !== undefined ? { "Content-Type": "application/json" } : {}),
      },
      body: init.body !== undefined ? JSON.stringify(init.body) : undefined,
      signal: AbortSignal.timeout(this.timeoutMs),
    });
    if (!response.ok) {
      throw new PalworldRestError(endpoint, response.status);
    }
    return response;
  }

  // Read endpoints parse JSON; mutation endpoints below deliberately ignore the
  // body - a 2xx is success even when the game returns plain text or nothing
  private async requestJson(endpoint: string): Promise<unknown> {
    const response = await this.request(endpoint);
    const text = await response.text();
    return text.length > 0 ? JSON.parse(text) : {};
  }

  async getInfo(): Promise<GameInfo> {
    return (await this.requestJson("info")) as GameInfo;
  }

  async getMetrics(): Promise<GameMetrics> {
    return (await this.requestJson("metrics")) as GameMetrics;
  }

  async getPlayers(): Promise<GamePlayer[]> {
    const data = (await this.requestJson("players")) as { players?: GamePlayer[] };
    return data.players ?? [];
  }

  async getSettings(): Promise<Record<string, unknown>> {
    return (await this.requestJson("settings")) as Record<string, unknown>;
  }

  async announce(message: string): Promise<void> {
    await this.request("announce", { body: { message } });
  }

  async save(): Promise<void> {
    await this.request("save", { method: "POST" });
  }

  async shutdown(waittime: number, message: string): Promise<void> {
    await this.request("shutdown", { body: { waittime, message } });
  }

  async kick(userid: string, message: string): Promise<void> {
    await this.request("kick", { body: { userid, message } });
  }

  async ban(userid: string, message: string): Promise<void> {
    await this.request("ban", { body: { userid, message } });
  }

  async unban(userid: string): Promise<void> {
    await this.request("unban", { body: { userid } });
  }
}
