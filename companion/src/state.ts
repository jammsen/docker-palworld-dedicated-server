import { mkdir, readFile, rename, writeFile } from "node:fs/promises";
import { join } from "node:path";

import type { ServerEvent } from "./events.js";

export interface CompanionState {
  discordMessageId?: string;
  sessionSecret?: string;
  lastRestartAt?: number;
  /** Ring buffer of recent server events (joins/leaves/up/down), newest last */
  events?: ServerEvent[];
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
    try {
      this.state = JSON.parse(await readFile(this.filePath, "utf8")) as CompanionState;
    } catch {
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
    // Serialize writes; atomic tmp+rename so bash/readers never see a torn file
    this.writeQueue = this.writeQueue.then(async () => {
      await mkdir(this.dataDir, { recursive: true });
      const tmpPath = `${this.filePath}.tmp`;
      await writeFile(tmpPath, snapshot, "utf8");
      await rename(tmpPath, this.filePath);
    });
    await this.writeQueue;
  }
}
