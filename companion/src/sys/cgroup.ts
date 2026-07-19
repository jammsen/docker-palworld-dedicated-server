import { readFile } from "node:fs/promises";
import { readMemInfo } from "./proc.js";

export interface RamUsage {
  usedBytes: number;
  totalBytes: number;
}

async function readNumberFile(path: string): Promise<number | null> {
  try {
    const raw = (await readFile(path, "utf8")).trim();
    if (raw === "max") return null;
    const value = Number.parseInt(raw, 10);
    return Number.isFinite(value) ? value : null;
  } catch {
    return null;
  }
}

// Container RAM usage: cgroup v2, then cgroup v1, then plain /proc/meminfo.
// An unlimited cgroup ("max") falls back to the host total from /proc/meminfo.
export async function readRamUsage(): Promise<RamUsage> {
  const memInfo = await readMemInfo().catch(() => ({ totalBytes: 0, availableBytes: 0 }));
  const hostTotal = memInfo.totalBytes;

  const v2Current = await readNumberFile("/sys/fs/cgroup/memory.current");
  if (v2Current !== null) {
    const v2Max = await readNumberFile("/sys/fs/cgroup/memory.max");
    return { usedBytes: v2Current, totalBytes: v2Max ?? hostTotal };
  }

  const v1Usage = await readNumberFile("/sys/fs/cgroup/memory/memory.usage_in_bytes");
  if (v1Usage !== null) {
    const v1Limit = await readNumberFile("/sys/fs/cgroup/memory/memory.limit_in_bytes");
    // cgroup v1 reports "no limit" as a huge page-aligned number instead of "max"
    const limitIsReal = v1Limit !== null && v1Limit < hostTotal * 2;
    return { usedBytes: v1Usage, totalBytes: limitIsReal ? v1Limit : hostTotal };
  }

  return { usedBytes: hostTotal - memInfo.availableBytes, totalBytes: hostTotal };
}
