import type { CompanionConfig } from "../config.js";
import { log } from "../logger.js";
import type { GameMetrics, GamePlayer, PalworldClient } from "../palworld/client.js";
import { readServerNameFromIni } from "../palworld/ini.js";
import type { StateStore } from "../state.js";
import { readRamUsage, type RamUsage } from "../sys/cgroup.js";
import { cpuUsagePercent, readProcStat, type CpuCoreSample } from "../sys/proc.js";

export interface StatusSnapshot {
  at: number;
  serverUp: boolean;
  game: GameMetrics | null;
  players: GamePlayer[];
  serverName: string;
  cpuCorePercents: number[];
  ram: RamUsage;
  lastRestartAt: number | null;
}

// Samples game + system metrics. One collector instance feeds both the Discord
// card and the web panel, so the game API is polled once per interval at most.
export class MetricsCollector {
  private previousCpuSample: CpuCoreSample[] = [];
  private cachedServerName = "";
  private lastSnapshot: StatusSnapshot | null = null;

  constructor(
    private readonly config: CompanionConfig,
    private readonly client: PalworldClient,
    private readonly state: StateStore,
  ) {}

  latest(): StatusSnapshot | null {
    return this.lastSnapshot;
  }

  // Serve a cached snapshot when it is fresh enough; the panel uses this so
  // many open browser tabs never multiply the polling of the game API.
  async getFresh(maxAgeMs: number): Promise<StatusSnapshot> {
    if (this.lastSnapshot && Date.now() - this.lastSnapshot.at < maxAgeMs) {
      return this.lastSnapshot;
    }
    return this.collect();
  }

  async collect(): Promise<StatusSnapshot> {
    let game: GameMetrics | null = null;
    let players: GamePlayer[] = [];

    if (this.config.restapi.enabled) {
      try {
        game = await this.client.getMetrics();
        players = await this.client.getPlayers();
        if (!this.cachedServerName) {
          this.cachedServerName = (await this.client.getInfo().catch(() => null))?.servername ?? "";
        }
      } catch (error) {
        log.debug(`game REST API unreachable: ${String(error)}`);
        game = null;
      }
    }

    if (!this.cachedServerName) {
      // /info not answered yet (or REST disabled): the generated INI holds the
      // effective name, including the boot-time ###RANDOM### substitution the
      // companion's own environment never sees
      this.cachedServerName = (await readServerNameFromIni(this.config.gameSettingsFile)) ?? "";
    }

    let cpuCorePercents: number[] = [];
    try {
      if (this.previousCpuSample.length === 0) {
        // First collection: take a short double sample so the very first
        // snapshot already has meaningful per-core percentages
        this.previousCpuSample = await readProcStat();
        await new Promise((resolve) => setTimeout(resolve, 500));
      }
      const cpuSample = await readProcStat();
      cpuCorePercents = cpuUsagePercent(this.previousCpuSample, cpuSample);
      this.previousCpuSample = cpuSample;
    } catch (error) {
      log.debug(`/proc/stat read failed: ${String(error)}`);
    }

    const ram = await readRamUsage();

    // Derive the last restart from server uptime; persist so it survives companion restarts
    let lastRestartAt = this.state.get().lastRestartAt ?? null;
    if (game) {
      const derived = Date.now() - game.uptime * 1000;
      // Only rewrite when it moved by more than a minute (uptime resolution jitter)
      if (lastRestartAt === null || Math.abs(derived - lastRestartAt) > 60_000) {
        lastRestartAt = derived;
        await this.state.update({ lastRestartAt: derived });
      }
    }

    this.lastSnapshot = {
      at: Date.now(),
      serverUp: game !== null,
      game,
      players,
      serverName: this.cachedServerName || this.config.serverName,
      cpuCorePercents,
      ram,
      lastRestartAt,
    };
    return this.lastSnapshot;
  }
}
