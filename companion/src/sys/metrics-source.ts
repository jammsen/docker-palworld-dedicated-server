import { cpuUsagePercent, readMemInfo, readProcStat, type CpuCoreSample } from "./proc.js";

export interface RamUsage {
  usedBytes: number;
  totalBytes: number;
}

export interface SystemMetrics {
  cpuCorePercents: number[];
  ram: RamUsage;
}

// Seam for where CPU/RAM numbers come from. As a sidecar the companion's own
// cgroup says nothing about the gameserver, so the shipped source reports
// host-wide numbers; per-container sources (shared cgroup namespace, docker
// API) can be added behind this interface without touching the collector.
export interface SystemMetricsSource {
  /** What the numbers describe - drives the "Host ..." labels in the UI */
  readonly scope: "host";
  sample(): Promise<SystemMetrics>;
}

// Host-wide metrics from /proc/stat and /proc/meminfo - both report the whole
// machine from inside any container, no extra Docker configuration needed.
export class HostProcMetricsSource implements SystemMetricsSource {
  readonly scope = "host";
  private previousCpuSample: CpuCoreSample[] = [];

  async sample(): Promise<SystemMetrics> {
    let cpuCorePercents: number[] = [];
    try {
      if (this.previousCpuSample.length === 0) {
        // First sample: take a short double sample so the very first
        // snapshot already has meaningful per-core percentages
        this.previousCpuSample = await readProcStat();
        await new Promise((resolve) => setTimeout(resolve, 500));
      }
      const cpuSample = await readProcStat();
      cpuCorePercents = cpuUsagePercent(this.previousCpuSample, cpuSample);
      this.previousCpuSample = cpuSample;
    } catch {
      // /proc/stat unavailable (exotic runtime) - show no CPU bars
    }

    const memInfo = await readMemInfo().catch(() => ({ totalBytes: 0, availableBytes: 0 }));
    const ram: RamUsage = {
      usedBytes: memInfo.totalBytes - memInfo.availableBytes,
      totalBytes: memInfo.totalBytes,
    };
    return { cpuCorePercents, ram };
  }
}
