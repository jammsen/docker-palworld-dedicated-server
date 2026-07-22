import { describe, expect, it } from "vitest";
import { cpuUsagePercent, parseMemInfo, parseProcStat } from "../src/sys/proc.js";

const PROC_STAT_T0 = `cpu  1000 0 500 8000 100 0 50 0 0 0
cpu0 500 0 250 4000 50 0 25 0 0 0
cpu1 500 0 250 4000 50 0 25 0 0 0
intr 12345
ctxt 6789
`;

const PROC_STAT_T1 = `cpu  1400 0 700 8400 100 0 50 0 0 0
cpu0 900 0 450 4000 50 0 25 0 0 0
cpu1 500 0 250 4400 50 0 25 0 0 0
intr 12345
ctxt 6789
`;

describe("parseProcStat", () => {
  it("parses per-core samples and skips the aggregate line", () => {
    const cores = parseProcStat(PROC_STAT_T0);
    expect(cores).toHaveLength(2);
    expect(cores[0]).toEqual({ idle: 4050, total: 4825 });
  });
});

describe("cpuUsagePercent", () => {
  it("computes busy percentage from two samples", () => {
    const percents = cpuUsagePercent(parseProcStat(PROC_STAT_T0), parseProcStat(PROC_STAT_T1));
    // core0: delta total 600, idle unchanged -> 100% busy
    // core1: delta total 400, all idle -> 0% busy
    expect(percents).toEqual([100, 0]);
  });

  it("returns 0 for unknown or unchanged cores", () => {
    const sample = parseProcStat(PROC_STAT_T0);
    expect(cpuUsagePercent([], sample)).toEqual([0, 0]);
    expect(cpuUsagePercent(sample, sample)).toEqual([0, 0]);
  });
});

describe("parseMemInfo", () => {
  it("extracts total and available memory in bytes", () => {
    const memInfo = parseMemInfo("MemTotal:       16384000 kB\nMemFree:         1000000 kB\nMemAvailable:    8192000 kB\n");
    expect(memInfo.totalBytes).toBe(16384000 * 1024);
    expect(memInfo.availableBytes).toBe(8192000 * 1024);
  });
});
