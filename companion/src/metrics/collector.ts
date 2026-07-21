import { readFile } from "node:fs/promises";
import { join } from "node:path";
import type { CompanionConfig } from "../config.js";
import { appendEvents, eventKey, parseShellEvents, serverStateEvents, type ServerEvent } from "../events.js";
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
  /** Recent server events, newest last */
  events: ServerEvent[];
}

// Samples game + system metrics. One collector instance feeds both the Discord
// card and the web panel, so the game API is polled once per interval at most.
export class MetricsCollector {
  private previousCpuSample: CpuCoreSample[] = [];
  private cachedServerName = "";
  private lastSnapshot: StatusSnapshot | null = null;
  private seenShellEvents: Set<string> | null = null;
  private collecting: Promise<StatusSnapshot> | null = null;

  constructor(
    private readonly config: CompanionConfig,
    private readonly client: PalworldClient,
    private readonly state: StateStore,
  ) {}

  /** Record an event originating inside the companion itself (e.g. panel settings save) */
  async recordEvent(event: ServerEvent): Promise<void> {
    const events = appendEvents(this.state.get().events ?? [], [event]);
    await this.state.update({ events });
    if (this.lastSnapshot) this.lastSnapshot = { ...this.lastSnapshot, events };
  }

  /**
   * Cheap event-only refresh for the SIGTERM path: ingest the shell event file
   * (e.g. the 'stopping' marker written moments earlier) without touching the
   * game REST API, which is going down at that point. Returns the freshest
   * snapshot for the final Discord card edit.
   */
  async refreshEventsOnly(): Promise<StatusSnapshot | null> {
    const newEvents = await this.ingestShellEvents();
    if (newEvents.length > 0) {
      const events = appendEvents(this.state.get().events ?? [], newEvents);
      await this.state.update({ events });
      if (this.lastSnapshot) this.lastSnapshot = { ...this.lastSnapshot, events };
    }
    return this.lastSnapshot;
  }

  // Ingest events written by the shell side (includes/companion.sh
  // log_companion_event). Dedupe by event key: the file is re-read whole each
  // tick (it is trimmed to <=200 lines), and on companion restart the keys of
  // already-persisted events prevent re-ingestion.
  private async ingestShellEvents(): Promise<ServerEvent[]> {
    let content: string;
    try {
      content = await readFile(join(this.config.dataDir, "events.log"), "utf8");
    } catch {
      return [];
    }
    if (this.seenShellEvents === null) {
      this.seenShellEvents = new Set((this.state.get().events ?? []).map(eventKey));
    }
    const fresh: ServerEvent[] = [];
    for (const event of parseShellEvents(content)) {
      const key = eventKey(event);
      if (this.seenShellEvents.has(key)) continue;
      this.seenShellEvents.add(key);
      fresh.push(event);
    }
    return fresh;
  }

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

  // Coalesce overlapping calls (Discord tick + panel getFresh) into one run:
  // the game API is polled once and state writes cannot interleave.
  async collect(): Promise<StatusSnapshot> {
    this.collecting ??= this.doCollect().finally(() => {
      this.collecting = null;
    });
    return this.collecting;
  }

  private async doCollect(): Promise<StatusSnapshot> {
    let game: GameMetrics | null = null;
    let players: GamePlayer[] = [];

    if (this.config.restapi.enabled) {
      try {
        [game, players] = await Promise.all([this.client.getMetrics(), this.client.getPlayers()]);
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

    // Events: the shell side is the single source for everything it observes
    // (player detection, SteamCMD, restarts, backups) via the event file; the
    // companion only contributes REST up/down transitions. No previous
    // snapshot (companion just started) means no transition to detect.
    const newEvents = await this.ingestShellEvents();
    if (this.lastSnapshot !== null) {
      newEvents.push(...serverStateEvents(this.lastSnapshot.serverUp, game !== null, Date.now()));
    }
    // Read events only after the awaits above: recordEvent() may have appended
    // meanwhile, and state.update applies patches synchronously, so this
    // read-append-update cannot interleave with other mutations.
    let events = this.state.get().events ?? [];
    if (newEvents.length > 0) {
      events = appendEvents(events, newEvents);
      await this.state.update({ events });
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
      events,
    };
    return this.lastSnapshot;
  }
}
