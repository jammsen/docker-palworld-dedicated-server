import { readFile } from "node:fs/promises";
import type { CompanionConfig } from "../config.js";
import { EventLogWriter } from "../eventlog.js";
import { mergeEvents, parseEventLog, serverStateEvents, type EventSource, type ServerEvent } from "../events.js";
import { log } from "../logger.js";
import type { GameMetrics, GamePlayer, PalworldClient } from "../palworld/client.js";
import { readServerNameFromIni } from "../palworld/ini.js";
import type { StateStore } from "../state.js";
import type { RamUsage, SystemMetricsSource } from "../sys/metrics-source.js";

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
  private cachedServerName = "";
  private lastSnapshot: StatusSnapshot | null = null;
  private collecting: Promise<StatusSnapshot> | null = null;
  private readonly eventWriter: EventLogWriter;

  constructor(
    private readonly config: CompanionConfig,
    private readonly client: PalworldClient,
    private readonly state: StateStore,
    private readonly metricsSource: SystemMetricsSource,
  ) {
    this.eventWriter = new EventLogWriter(config.companionEventsFile);
  }

  /** Record an event originating inside the companion itself (e.g. panel settings save) */
  async recordEvent(event: ServerEvent): Promise<void> {
    await this.eventWriter.append(event);
    if (this.lastSnapshot) {
      this.lastSnapshot = { ...this.lastSnapshot, events: await this.readMergedEvents() };
    }
  }

  /**
   * Cheap event-only refresh for the SIGTERM path: re-read the event logs
   * (e.g. the 'stopping' marker written moments earlier by the gameserver)
   * without touching the game REST API, which is going down at that point.
   * Returns the freshest snapshot for the final Discord card edit.
   */
  async refreshEventsOnly(): Promise<StatusSnapshot | null> {
    if (this.lastSnapshot) {
      this.lastSnapshot = { ...this.lastSnapshot, events: await this.readMergedEvents() };
    }
    return this.lastSnapshot;
  }

  // The two log files ARE the event store: both are bounded by their writers,
  // so each read simply re-parses them whole and merges by timestamp. No
  // in-memory bookkeeping, nothing persisted to state.json.
  private async readMergedEvents(): Promise<ServerEvent[]> {
    const [game, companion] = await Promise.all([
      this.readEventLog(this.config.gameEventsFile, "game"),
      this.readEventLog(this.config.companionEventsFile, "companion"),
    ]);
    return mergeEvents(game, companion);
  }

  private async readEventLog(filePath: string, source: EventSource): Promise<ServerEvent[]> {
    try {
      return parseEventLog(await readFile(filePath, "utf8"), source);
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code === "ENOENT") {
        return []; // Missing file = no events yet (or no mount) - not an error
      }
      // Permission/I-O problems must stay diagnosable instead of looking like an empty log
      log.warn(`>>> Failed to read ${source} event log at ${filePath}: ${String(error)}`);
      return [];
    }
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

    // A failing metrics source (future per-container implementations) must
    // not take down the whole collection - game data and events still matter
    let cpuCorePercents: number[] = [];
    let ram: RamUsage = { usedBytes: 0, totalBytes: 0 };
    try {
      ({ cpuCorePercents, ram } = await this.metricsSource.sample());
    } catch (error) {
      log.debug(`system metrics sampling failed: ${String(error)}`);
    }

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

    // Events: the gameserver is the single source for everything it observes
    // (player detection, SteamCMD, restarts, backups) via game-events.log; the
    // companion only contributes REST up/down transitions, persisted to its
    // own companion-events.log. No previous snapshot (companion just started)
    // means no transition to detect.
    if (this.lastSnapshot !== null) {
      for (const event of serverStateEvents(this.lastSnapshot.serverUp, game !== null, Date.now())) {
        await this.eventWriter.append(event);
      }
    }
    const events = await this.readMergedEvents();

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
