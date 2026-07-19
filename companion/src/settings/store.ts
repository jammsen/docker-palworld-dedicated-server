import { mkdir, readFile, rename, stat, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { normalizeSettingValue, settingsSchema, type SettingSpec } from "./schema.js";

export type Provenance = "default" | "env" | "override";

export interface EffectiveSetting {
  spec: SettingSpec;
  /** Value the server will use at the next restart (override > env > default) */
  value: string;
  /** Value from container env / default, i.e. what a "reset" reverts to */
  envValue: string;
  provenance: Provenance;
}

const OVERRIDES_HEADER = `# Managed by the palworld-companion web panel - do not edit while the panel is running.
# Applied by includes/config.sh in SERVER_SETTINGS_MODE=auto with highest precedence:
#   template default < container env (default.env) < this file
`;

export class SettingsStore {
  private readonly filePath: string;
  private writeQueue: Promise<void> = Promise.resolve();

  constructor(
    private readonly dataDir: string,
    private readonly env: Record<string, string | undefined>,
  ) {
    this.filePath = join(dataDir, "settings-overrides.env");
  }

  async readOverrides(): Promise<Map<string, string>> {
    const overrides = new Map<string, string>();
    let content: string;
    try {
      content = await readFile(this.filePath, "utf8");
    } catch {
      return overrides;
    }
    for (const line of content.split("\n")) {
      if (/^\s*(#|$)/.test(line)) continue;
      const match = /^([A-Z0-9_]+)=(.*)$/.exec(line);
      if (match) overrides.set(match[1]!, match[2]!);
    }
    return overrides;
  }

  async writeOverrides(overrides: Map<string, string>): Promise<void> {
    const lines = [...overrides.entries()]
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([key, value]) => `${key}=${value}`);
    const content = `${OVERRIDES_HEADER}${lines.join("\n")}${lines.length > 0 ? "\n" : ""}`;
    this.writeQueue = this.writeQueue.then(async () => {
      await mkdir(this.dataDir, { recursive: true });
      const tmpPath = `${this.filePath}.tmp`;
      await writeFile(tmpPath, content, "utf8");
      await rename(tmpPath, this.filePath);
    });
    await this.writeQueue;
  }

  /** Env value if set, otherwise the schema default - what "reset" reverts to */
  envValue(spec: SettingSpec): string {
    return this.env[spec.key] ?? spec.default;
  }

  async effectiveSettings(): Promise<EffectiveSetting[]> {
    const overrides = await this.readOverrides();
    return settingsSchema.map((spec) => {
      if (spec.secret) {
        // Never expose secret values to any consumer (UI, JSON, export)
        return { spec, value: "", envValue: "", provenance: "env" as const };
      }
      const envValue = this.envValue(spec);
      const override = overrides.get(spec.key);
      if (override !== undefined && !spec.excluded) {
        return { spec, value: override, envValue, provenance: "override" as const };
      }
      const provenance: Provenance = this.env[spec.key] !== undefined && this.env[spec.key] !== spec.default ? "env" : "default";
      return { spec, value: envValue, envValue, provenance };
    });
  }

  /**
   * Apply submitted values: keys equal to their env/default value drop their
   * override, differing keys get one. Returns the number of override changes.
   */
  async applySubmission(submitted: Map<string, string>): Promise<number> {
    const overrides = await this.readOverrides();
    let changes = 0;
    for (const spec of settingsSchema) {
      if (spec.excluded) continue;
      const raw = submitted.get(spec.key);
      if (raw === undefined) continue;
      const value = normalizeSettingValue(spec, raw);
      const envValue = this.envValue(spec);
      const hadOverride = overrides.has(spec.key);
      if (value === normalizeSettingValue(spec, envValue)) {
        if (hadOverride) {
          overrides.delete(spec.key);
          changes += 1;
        }
      } else if (!hadOverride || overrides.get(spec.key) !== value) {
        overrides.set(spec.key, value);
        changes += 1;
      }
    }
    if (changes > 0) await this.writeOverrides(overrides);
    return changes;
  }

  async resetOverride(key: string): Promise<void> {
    const overrides = await this.readOverrides();
    if (overrides.delete(key)) await this.writeOverrides(overrides);
  }

  async resetAllOverrides(): Promise<void> {
    await this.writeOverrides(new Map());
  }

  /** Pending changes = overrides file written after the INI was last generated */
  async restartPending(gameSettingsFile: string): Promise<boolean> {
    try {
      const overridesStat = await stat(this.filePath);
      const overrides = await this.readOverrides();
      if (overrides.size === 0) return false;
      try {
        const iniStat = await stat(gameSettingsFile);
        return overridesStat.mtimeMs > iniStat.mtimeMs;
      } catch {
        return true; // INI not generated yet - overrides will apply at next boot
      }
    } catch {
      return false; // no overrides file
    }
  }

  /**
   * Render the effective settings as a .env export for host-side syncing.
   *
   * Mirrors the shipped default.env template line by line - same key order,
   * same section comments - so users can diff it against their own default.env
   * (e.g. VS Code "Select for Compare"). Only known gameserver settings get
   * their value replaced; comments, secrets and non-gameserver lines (backup,
   * webhook, ...) stay verbatim, because the container cannot see the host's
   * actual default.env values for those.
   */
  async exportEnv(template?: string): Promise<string> {
    const settings = await this.effectiveSettings();
    const byKey = new Map(settings.map((s) => [s.spec.key, s]));
    const header = `# Effective Palworld settings exported by the companion panel\n# Generated: ${new Date().toISOString()}\n# Gameserver settings reflect the running configuration (env + panel overrides);\n# all other lines are the shipped defaults - the container cannot read your host default.env.\n`;

    if (!template) {
      // Fallback without a template: schema order, which groups related keys
      const lines = settings.filter((s) => !s.spec.excluded).map((s) => `${s.spec.key}=${s.value}`);
      return `${header}${lines.join("\n")}\n`;
    }

    const rendered = template
      .split("\n")
      .map((line) => {
        const match = /^([A-Z0-9_]+)=(.*)$/.exec(line);
        if (!match) return line; // comments, blanks - keep verbatim
        const setting = byKey.get(match[1]!);
        if (!setting || setting.spec.secret) return line; // unknown or secret - keep template value
        const wasQuoted = /^".*"$/.test(match[2]!);
        return `${match[1]}=${wasQuoted ? `"${setting.value}"` : setting.value}`;
      })
      .join("\n");
    return `${header}${rendered}`;
  }
}
