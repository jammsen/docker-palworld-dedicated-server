import { readFile } from "node:fs/promises";

export interface CpuCoreSample {
  idle: number;
  total: number;
}

// Parse per-core counters out of /proc/stat ("cpu0 ..." lines; the aggregate "cpu" line is skipped)
export function parseProcStat(text: string): CpuCoreSample[] {
  const cores: CpuCoreSample[] = [];
  for (const line of text.split("\n")) {
    const match = /^cpu(\d+)\s+(.*)$/.exec(line);
    if (!match) continue;
    const values = (match[2] ?? "")
      .trim()
      .split(/\s+/)
      .map((v) => Number.parseInt(v, 10))
      .filter((v) => Number.isFinite(v));
    // Fields: user nice system idle iowait irq softirq steal guest guest_nice
    const idle = (values[3] ?? 0) + (values[4] ?? 0);
    const total = values.reduce((sum, v) => sum + v, 0);
    cores[Number.parseInt(match[1] ?? "0", 10)] = { idle, total };
  }
  return cores;
}

// Busy percentage per core between two samples
export function cpuUsagePercent(previous: CpuCoreSample[], current: CpuCoreSample[]): number[] {
  return current.map((sample, index) => {
    const prev = previous[index];
    if (!prev) return 0;
    const totalDelta = sample.total - prev.total;
    const idleDelta = sample.idle - prev.idle;
    if (totalDelta <= 0) return 0;
    const percent = Math.round(((totalDelta - idleDelta) / totalDelta) * 100);
    return Math.min(100, Math.max(0, percent));
  });
}

export interface MemInfo {
  totalBytes: number;
  availableBytes: number;
}

export function parseMemInfo(text: string): MemInfo {
  let totalBytes = 0;
  let availableBytes = 0;
  for (const line of text.split("\n")) {
    const match = /^(MemTotal|MemAvailable):\s+(\d+)\s+kB/.exec(line);
    if (!match) continue;
    const bytes = Number.parseInt(match[2] ?? "0", 10) * 1024;
    if (match[1] === "MemTotal") totalBytes = bytes;
    else availableBytes = bytes;
  }
  return { totalBytes, availableBytes };
}

export async function readProcStat(): Promise<CpuCoreSample[]> {
  return parseProcStat(await readFile("/proc/stat", "utf8"));
}

export async function readMemInfo(): Promise<MemInfo> {
  return parseMemInfo(await readFile("/proc/meminfo", "utf8"));
}
