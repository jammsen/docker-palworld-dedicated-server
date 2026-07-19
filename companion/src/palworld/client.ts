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

  private async request(endpoint: string, body?: unknown): Promise<unknown> {
    const response = await this.fetchFn(this.baseUrl + endpoint, {
      method: body === undefined ? "GET" : "POST",
      headers: {
        Authorization: this.authHeader,
        Accept: "application/json",
        ...(body !== undefined ? { "Content-Type": "application/json" } : {}),
      },
      body: body !== undefined ? JSON.stringify(body) : undefined,
      signal: AbortSignal.timeout(this.timeoutMs),
    });
    if (!response.ok) {
      throw new PalworldRestError(endpoint, response.status);
    }
    const text = await response.text();
    return text.length > 0 ? JSON.parse(text) : {};
  }

  async getInfo(): Promise<GameInfo> {
    return (await this.request("info")) as GameInfo;
  }

  async getMetrics(): Promise<GameMetrics> {
    return (await this.request("metrics")) as GameMetrics;
  }

  async getPlayers(): Promise<GamePlayer[]> {
    const data = (await this.request("players")) as { players?: GamePlayer[] };
    return data.players ?? [];
  }

  async getSettings(): Promise<Record<string, unknown>> {
    return (await this.request("settings")) as Record<string, unknown>;
  }

  async announce(message: string): Promise<void> {
    await this.request("announce", { message });
  }

  async save(): Promise<void> {
    await this.request("save", {});
  }

  async shutdown(waittime: number, message: string): Promise<void> {
    await this.request("shutdown", { waittime, message });
  }

  async kick(userid: string, message: string): Promise<void> {
    await this.request("kick", { userid, message });
  }

  async ban(userid: string, message: string): Promise<void> {
    await this.request("ban", { userid, message });
  }

  async unban(userid: string): Promise<void> {
    await this.request("unban", { userid });
  }
}
