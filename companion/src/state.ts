import { mkdir, readFile, rename, writeFile } from "node:fs/promises";
import { join } from "node:path";

import { log } from "./logger.js";

export interface CompanionState {
  discordMessageId?: string;
  sessionSecret?: string;
  lastRestartAt?: number;
}

// Persistent state on the game volume - survives container restarts AND re-creation
export class StateStore {
  private readonly filePath: string;
  private state: CompanionState = {};
  private writeQueue: Promise<void> = Promise.resolve();

  constructor(private readonly dataDir: string) {
    this.filePath = join(dataDir, "state.json");
  }

  async load(): Promise<CompanionState> {
    let raw: string;
    try {
      raw = await readFile(this.filePath, "utf8");
    } catch (error) {
      // Missing file = first start. Anything else (permissions, I/O) must
      // surface instead of silently discarding persisted state.
      if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
      this.state = {};
      return this.state;
    }
    try {
      this.state = JSON.parse(raw) as CompanionState;
      // Events moved to companion-events.log; drop the legacy ring buffer so
      // it is not re-serialized forever
      delete (this.state as Record<string, unknown>).events;
    } catch {
      log.warn(`>>> ${this.filePath} contains invalid JSON - starting with empty state`);
      this.state = {};
    }
    return this.state;
  }

  get(): CompanionState {
    return this.state;
  }

  async update(patch: Partial<CompanionState>): Promise<void> {
    this.state = { ...this.state, ...patch };
    const snapshot = JSON.stringify(this.state, null, 2);
    // Serialize writes; atomic tmp+rename so bash/readers never see a torn file.
    // Recover a rejected chain before appending so a transient error doesn't
    // permanently break every future write.
    this.writeQueue = this.writeQueue.catch(() => {}).then(async () => {
      await mkdir(this.dataDir, { recursive: true, mode: 0o700 });
      const tmpPath = `${this.filePath}.tmp`;
      // 0600: the file holds the session-signing secret; rename keeps the mode
      await writeFile(tmpPath, snapshot, { encoding: "utf8", mode: 0o600 });
      await rename(tmpPath, this.filePath);
    });
    await this.writeQueue;
  }
}
