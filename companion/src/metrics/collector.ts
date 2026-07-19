import type { CompanionConfig } from "../config.js";
import { log } from "../logger.js";
import type { GameMetrics, GamePlayer, PalworldClient } from "../palworld/client.js";
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

    let cpuCorePercents: number[] = [];
    try {
      const cpuSample = await readProcStat();
      if (this.previousCpuSample.length > 0) {
        cpuCorePercents = cpuUsagePercent(this.previousCpuSample, cpuSample);
      }
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
