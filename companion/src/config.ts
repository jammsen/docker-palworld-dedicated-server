// Typed parsing and validation of the container environment.
// Validation rules live here (not in bash) to keep the shell wiring minimal.

export interface CompanionConfig {
  debug: boolean;
  dataDir: string;
  gameRoot: string;
  panel: PanelConfig | null;
  discord: DiscordStatusConfig | null;
  restapi: RestApiConfig;
  serverName: string;
  serverSettingsMode: string;
  /** Reason strings for features that were requested but could not be enabled */
  warnings: string[];
}

export interface PanelConfig {
  port: number;
  username: string;
  password: string;
  defaultLanguage: string;
}

export interface DiscordStatusConfig {
  webhookUrl: string;
  updateIntervalSeconds: number;
}

export interface RestApiConfig {
  enabled: boolean;
  port: number;
  timeoutSeconds: number;
  adminPassword: string;
}

export const MIN_DISCORD_INTERVAL_SECONDS = 15;

function envBool(value: string | undefined): boolean {
  return (value ?? "").toLowerCase() === "true";
}

function envInt(value: string | undefined, fallback: number): number {
  const parsed = Number.parseInt(value ?? "", 10);
  return Number.isFinite(parsed) ? parsed : fallback;
}

export function parseConfig(env: Record<string, string | undefined>): CompanionConfig {
  const warnings: string[] = [];
  const gameRoot = env.GAME_ROOT || "/palworld";

  let panel: PanelConfig | null = null;
  if (envBool(env.PANEL_ENABLED)) {
    const password = env.PANEL_PASSWORD ?? "";
    if (password.length === 0) {
      warnings.push(
        "PANEL_ENABLED is true but PANEL_PASSWORD is empty - refusing to start the web panel without a password",
      );
    } else {
      panel = {
        port: envInt(env.PANEL_PORT, 8213),
        username: env.PANEL_USERNAME || "admin",
        password,
        defaultLanguage: env.PANEL_DEFAULT_LANGUAGE || "en",
      };
    }
  }

  let discord: DiscordStatusConfig | null = null;
  if (envBool(env.DISCORD_STATUS_ENABLED)) {
    const webhookUrl = env.DISCORD_STATUS_WEBHOOK_URL || env.WEBHOOK_URL || "";
    if (webhookUrl.length === 0) {
      warnings.push(
        "DISCORD_STATUS_ENABLED is true but neither DISCORD_STATUS_WEBHOOK_URL nor WEBHOOK_URL is set - disabling the Discord status card",
      );
    } else {
      const requested = envInt(env.DISCORD_STATUS_UPDATE_INTERVAL, 30);
      const updateIntervalSeconds = Math.max(requested, MIN_DISCORD_INTERVAL_SECONDS);
      if (updateIntervalSeconds !== requested) {
        warnings.push(
          `DISCORD_STATUS_UPDATE_INTERVAL=${requested} is below the webhook rate-limit safety minimum - clamped to ${MIN_DISCORD_INTERVAL_SECONDS} seconds`,
        );
      }
      discord = { webhookUrl, updateIntervalSeconds };
    }
  }

  const restapi: RestApiConfig = {
    enabled: envBool(env.RESTAPI_ENABLED),
    port: envInt(env.RESTAPI_PORT, 8212),
    timeoutSeconds: envInt(env.RESTAPI_TIMEOUT, 10),
    adminPassword: env.ADMIN_PASSWORD ?? "",
  };

  if ((panel || discord) && !restapi.enabled) {
    warnings.push(
      "RESTAPI_ENABLED is not true - game data (players, metrics, actions) will be unavailable to the companion service",
    );
  }

  return {
    debug: envBool(env.COMPANION_DEBUG),
    dataDir: `${gameRoot}/companion`,
    gameRoot,
    panel,
    discord,
    restapi,
    serverName: env.SERVER_NAME || "Palworld Dedicated Server",
    serverSettingsMode: (env.SERVER_SETTINGS_MODE || "manual").toLowerCase(),
    warnings,
  };
}
