import { appendFile, mkdir, readFile, rename, writeFile } from "node:fs/promises";
import { dirname } from "node:path";

import { formatEventLine, type ServerEvent } from "./events.js";

// Append-only writer for companion-events.log. The companion is the only
// writer of this file (the gameserver mounts the data dir read-only), so
// trimming happens here - the same writer-owns-trimming rule as
// includes/gameevents.sh on the gameserver side.
export class EventLogWriter {
  private writeQueue: Promise<void> = Promise.resolve();

  constructor(private readonly filePath: string) {}

  async append(event: ServerEvent): Promise<void> {
    // Serialize appends and trims so concurrent recordEvent calls cannot interleave
    this.writeQueue = this.writeQueue.catch(() => {}).then(async () => {
      await mkdir(dirname(this.filePath), { recursive: true });
      await appendFile(this.filePath, `${formatEventLine(event)}\n`, "utf8");
      await this.trim();
    });
    await this.writeQueue;
  }

  // Keep the file bounded (mirrors the gameserver-side trim: >200 lines -> last 100)
  private async trim(): Promise<void> {
    const lines = (await readFile(this.filePath, "utf8")).split("\n").filter((line) => line.length > 0);
    if (lines.length <= 200) return;
    const tmpPath = `${this.filePath}.tmp`;
    await writeFile(tmpPath, `${lines.slice(-100).join("\n")}\n`, "utf8");
    await rename(tmpPath, this.filePath);
  }
}
