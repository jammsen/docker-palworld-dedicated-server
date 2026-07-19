// Canonical catalog of every setting the container substitutes into
// PalWorldSettings.ini (plus NETSERVERMAXTICKRATE for Engine.ini).
// Single source of truth for form rendering, validation and provenance.
// A CI drift-guard test asserts this list matches ENVSUBST_SELECTORS in
// includes/config.sh, so a new game setting cannot be added in only one place.

export type SettingType = "float" | "int" | "bool" | "enum" | "string";

export type SettingGroup =
  | "server"
  | "rates"
  | "gameplay"
  | "pals"
  | "guild"
  | "building"
  | "items"
  | "pvp"
  | "network"
  | "advanced";

export interface SettingSpec {
  key: string;
  type: SettingType;
  default: string;
  group: SettingGroup;
  min?: number;
  max?: number;
  step?: number;
  values?: string[];
  /** Not editable via the panel: changing it would break the companion/server access itself */
  excluded?: boolean;
}

function f(key: string, def: string, group: SettingGroup, min = 0.1, max = 20, step = 0.1): SettingSpec {
  return { key, type: "float", default: def, group, min, max, step };
}

function i(key: string, def: string, group: SettingGroup, min = 0, max = 1_000_000): SettingSpec {
  return { key, type: "int", default: def, group, min, max };
}

function b(key: string, def: string, group: SettingGroup): SettingSpec {
  return { key, type: "bool", default: def, group };
}

function s(key: string, def: string, group: SettingGroup): SettingSpec {
  return { key, type: "string", default: def, group };
}

function en(key: string, def: string, group: SettingGroup, values: string[]): SettingSpec {
  return { key, type: "enum", default: def, group, values };
}

export const settingsSchema: SettingSpec[] = [
  // Server identity & access
  s("SERVER_NAME", "jammsen-docker-generated-###RANDOM###", "server"),
  s("SERVER_DESCRIPTION", "Palworld-Dedicated-Server running in Docker by jammsen", "server"),
  { ...s("ADMIN_PASSWORD", "adminPasswordHere", "server"), excluded: true },
  { ...s("SERVER_PASSWORD", "serverPasswordHere", "server"), excluded: true },
  i("MAX_PLAYERS", "32", "server", 1, 128),
  i("COOP_PLAYER_MAX_NUM", "4", "server", 1, 32),
  b("IS_MULTIPLAY", "false", "server"),
  b("USEAUTH", "true", "server"),
  s("REGION", "", "server"),
  s("BAN_LIST_URL", "https://b.palworldgame.com/api/banlist.txt", "server"),
  b("SHOW_PLAYER_LIST", "false", "server"),
  i("CHAT_POST_LIMIT_PER_MINUTE", "30", "server", 0, 1000),
  s("CROSSPLAY_PLATFORMS", "(Steam,Xbox,PS5,Mac)", "server"),
  en("LOG_FORMAT_TYPE", "Text", "server", ["Text", "Json"]),
  b("IS_SHOW_JOIN_LEFT_MESSAGE", "true", "server"),
  b("ENABLE_WORLD_BACKUP", "true", "server"),
  f("AUTO_SAVE_SPAN", "30.000000", "server", 1, 3600, 1),

  // Difficulty & randomizer
  en("DIFFICULTY", "None", "gameplay", ["None", "Casual", "Normal", "Hard", "Custom"]),
  en("RANDOMIZER_TYPE", "None", "gameplay", ["None", "Region", "All"]),
  s("RANDOMIZER_SEED", "", "gameplay"),
  b("IS_RANDOMIZER_PAL_LEVEL_RANDOM", "false", "gameplay"),
  en("DEATH_PENALTY", "Item", "gameplay", ["None", "Item", "ItemAndEquipment", "All"]),
  b("HARDCORE", "false", "gameplay"),
  b("PAL_LOST", "false", "gameplay"),
  b("CHARACTER_RECREATE_IN_HARDCORE", "false", "gameplay"),
  b("ENABLE_NON_LOGIN_PENALTY", "true", "gameplay"),
  b("ENABLE_FAST_TRAVEL", "true", "gameplay"),
  b("ENABLE_FAST_TRAVEL_ONLY_BASE_CAMP", "false", "gameplay"),
  b("IS_START_LOCATION_SELECT_BY_MAP", "false", "gameplay"),
  b("EXIST_PLAYER_AFTER_LOGOUT", "false", "gameplay"),
  b("ENABLE_INVADER_ENEMY", "true", "gameplay"),
  b("ENABLE_PREDATOR_BOSS_PAL", "true", "gameplay"),
  b("ACTIVE_UNKO", "false", "gameplay"),
  b("ENABLE_AIM_ASSIST_PAD", "true", "gameplay"),
  b("ENABLE_AIM_ASSIST_KEYBOARD", "false", "gameplay"),
  f("DAYTIME_SPEEDRATE", "1.000000", "gameplay"),
  f("NIGHTTIME_SPEEDRATE", "1.000000", "gameplay"),
  i("SUPPLY_DROP_SPAN", "180", "gameplay", 1, 100000),
  f("BLOCK_RESPAWN_TIME", "5.000000", "gameplay", 0, 3600, 0.5),
  f("RESPAWN_PENALTY_DURATION_THRESHOLD", "0.000000", "gameplay", 0, 3600, 0.5),
  f("RESPAWN_PENALTY_TIME_SCALE", "2.000000", "gameplay", 0, 100, 0.1),

  // Rates
  f("EXP_RATE", "1.000000", "rates"),
  f("WORK_SPEED_RATE", "1.000000", "rates"),
  f("PAL_CAPTURE_RATE", "1.000000", "rates"),
  f("PAL_SPAWN_NUM_RATE", "1.000000", "rates"),
  f("PAL_DAMAGE_RATE_ATTACK", "1.000000", "rates"),
  f("PAL_DAMAGE_RATE_DEFENSE", "1.000000", "rates"),
  f("PLAYER_DAMAGE_RATE_ATTACK", "1.000000", "rates"),
  f("PLAYER_DAMAGE_RATE_DEFENSE", "1.000000", "rates"),
  f("PLAYER_STOMACH_DECREASE_RATE", "1.000000", "rates"),
  f("PLAYER_STAMINA_DECREACE_RATE", "1.000000", "rates"),
  f("PLAYER_AUTO_HP_REGENE_RATE", "1.000000", "rates"),
  f("PLAYER_AUTO_HP_REGENE_RATE_IN_SLEEP", "1.000000", "rates"),
  f("PAL_STOMACH_DECREACE_RATE", "1.000000", "rates"),
  f("PAL_STAMINA_DECREACE_RATE", "1.000000", "rates"),
  f("PAL_AUTO_HP_REGENE_RATE", "1.000000", "rates"),
  f("PAL_AUTO_HP_REGENE_RATE_IN_SLEEP", "1.000000", "rates"),
  f("ENEMY_DROP_ITEM_RATE", "1.000000", "rates"),
  f("COLLECTION_DROP_RATE", "1.000000", "rates"),
  f("COLLECTION_OBJECT_HP_RATE", "1.000000", "rates"),
  f("COLLECTION_OBJECT_RESPAWN_SPEED_RATE", "1.000000", "rates"),
  f("ITEM_WEIGHT_RATE", "1.000000", "rates"),
  f("PAL_EGG_DEFAULT_HATCHING_TIME", "1.000000", "rates", 0, 240, 0.5),
  f("MONSTER_FARM_ACTION_SPEED_RATE", "1.000000", "rates"),
  f("ITEM_CORRUPTION_MULTIPLIER", "1.000000", "rates"),
  f("EQUIPMENT_DURABILITY_DAMAGE_RATE", "1.000000", "rates"),

  // Building & base camps
  f("BUILD_OBJECT_HP_RATE", "1.000000", "building"),
  f("BUILD_OBJECT_DAMAGE_RATE", "1.000000", "building"),
  f("BUILD_OBJECT_DETERIORATION_DAMAGE_RATE", "1.000000", "building"),
  b("BUILD_AREA_LIMIT", "false", "building"),
  i("MAX_BUILDING_LIMIT_NUM", "0", "building", 0, 100000),
  i("BASE_CAMP_MAX_NUM", "128", "building", 1, 1024),
  i("BASE_CAMP_WORKER_MAXNUM", "15", "building", 1, 100),
  b("ENABLE_BUILDING_PLAYER_UID_DISPLAY", "false", "building"),
  f("BUILDING_NAME_DISPLAY_CACHE_TTL_SECONDS", "60", "building", 1, 3600, 1),

  // Items
  i("DROP_ITEM_MAX_NUM", "3000", "items", 0, 100000),
  i("PHYSICS_ACTIVE_DROP_ITEM_MAX_NUM", "-1", "items", -1, 100000),
  i("DROP_ITEM_MAX_NUM_UNKO", "100", "items", 0, 100000),
  f("DROP_ITEM_ALIVE_MAX_HOURS", "1.000000", "items", 0, 240, 0.5),
  s("DENY_TECHNOLOGY_LIST", "", "items"),
  f("ITEM_CONTAINER_FORCE_MARK_DIRTY_INTERVAL", "1.000000", "items", 0.1, 3600, 0.1),
  f("PLAYER_DATA_PAL_STORAGE_UPDATE_CHECK_TICK_INTERVAL", "1.000000", "items", 0.1, 3600, 0.1),

  // Guild
  i("GUILD_PLAYER_MAX_NUM", "20", "guild", 1, 100),
  i("BASE_CAMP_MAX_NUM_IN_GUILD", "4", "guild", 1, 10),
  b("AUTO_RESET_GUILD_NO_ONLINE_PLAYERS", "false", "guild"),
  f("AUTO_RESET_GUILD_TIME_NO_ONLINE_PLAYERS", "72.000000", "guild", 1, 8760, 1),
  i("GUILD_REJOIN_COOLDOWN_MINUTES", "0", "guild", 0, 100000),
  f("AUTO_TRANSFER_MASTER_CHECK_INTERVAL_SECONDS", "3600.000000", "guild", 1, 86400, 1),
  i("AUTO_TRANSFER_MASTER_THRESHOLD_DAYS", "14", "guild", 1, 365),
  i("MAX_GUILDS_PER_FRAME", "10", "guild", 1, 1000),
  b("CAN_PICKUP_OTHER_GUILD_DEATH_PENALTY_DROP", "false", "guild"),
  b("ENABLE_DEFENSE_OTHER_GUILD_PLAYER", "false", "guild"),
  b("INVISBIBLE_OTHER_GUILD_BASE_CAMP_AREA_FX", "false", "guild"),
  b("ALLOW_GLOBAL_PALBOX_EXPORT", "true", "guild"),
  b("ALLOW_GLOBAL_PALBOX_IMPORT", "false", "guild"),

  // PvP
  b("IS_PVP", "false", "pvp"),
  b("ENABLE_PLAYER_TO_PLAYER_DAMAGE", "false", "pvp"),
  b("ENABLE_FRIENDLY_FIRE", "false", "pvp"),
  b("DISPLAY_PVP_ITEM_NUM_ON_WORLD_MAP_BASE_CAMP", "false", "pvp"),
  b("DISPLAY_PVP_ITEM_NUM_ON_WORLD_MAP_PLAYER", "false", "pvp"),
  en("ADDITIONAL_DROP_ITEM_WHEN_PLAYER_KILLING_IN_PVP_MODE", "PlayerDropItem", "pvp", ["PlayerDropItem"]),
  i("ADDITIONAL_DROP_ITEM_NUM_WHEN_PLAYER_KILLING_IN_PVP_MODE", "1", "pvp", 0, 1000),
  b("ENABLE_ADDITIONAL_DROP_ITEM_WHEN_PLAYER_KILLING_IN_PVP_MODE", "false", "pvp"),
  b("ALLOW_ENHANCE_STAT_HEALTH", "true", "pvp"),
  b("ALLOW_ENHANCE_STAT_ATTACK", "true", "pvp"),
  b("ALLOW_ENHANCE_STAT_STAMINA", "true", "pvp"),
  b("ALLOW_ENHANCE_STAT_WEIGHT", "true", "pvp"),
  b("ALLOW_ENHANCE_STAT_WORK_SPEED", "true", "pvp"),

  // Voice chat
  b("ENABLE_VOICE_CHAT", "false", "network"),
  f("VOICE_CHAT_MAX_VOLUME_DISTANCE", "3000.000000", "network", 1, 100000, 1),
  f("VOICE_CHAT_ZERO_VOLUME_DISTANCE", "15000.000000", "network", 1, 100000, 1),

  // Network & API
  i("PUBLIC_PORT", "8211", "network", 1, 65535),
  s("PUBLIC_IP", "", "network"),
  b("RCON_ENABLED", "false", "network"),
  i("RCON_PORT", "25575", "network", 1, 65535),
  { ...b("RESTAPI_ENABLED", "true", "network"), excluded: true },
  { ...i("RESTAPI_PORT", "8212", "network", 1, 65535), excluded: true },
  b("ALLOW_CLIENT_MOD", "true", "network"),
  f("SERVER_REPLICATE_PAWN_CULL_DISTANCE", "15000.000000", "network", 1, 100000, 1),
  i("NETSERVERMAXTICKRATE", "120", "network", 30, 240),
];

export const settingsByKey = new Map(settingsSchema.map((spec) => [spec.key, spec]));

export const settingGroups: SettingGroup[] = [
  "server",
  "gameplay",
  "rates",
  "building",
  "items",
  "guild",
  "pvp",
  "network",
];

export interface ValidationResult {
  ok: boolean;
  reason?: string;
}

export function validateSettingValue(spec: SettingSpec, value: string): ValidationResult {
  switch (spec.type) {
    case "bool":
      return value === "true" || value === "false" ? { ok: true } : { ok: false, reason: "must be true or false" };
    case "enum":
      return spec.values?.includes(value) ? { ok: true } : { ok: false, reason: `must be one of: ${spec.values?.join(", ")}` };
    case "int": {
      if (!/^-?\d+$/.test(value)) return { ok: false, reason: "must be an integer" };
      const parsed = Number.parseInt(value, 10);
      if (spec.min !== undefined && parsed < spec.min) return { ok: false, reason: `must be >= ${spec.min}` };
      if (spec.max !== undefined && parsed > spec.max) return { ok: false, reason: `must be <= ${spec.max}` };
      return { ok: true };
    }
    case "float": {
      if (!/^-?\d+(\.\d+)?$/.test(value)) return { ok: false, reason: "must be a number" };
      const parsed = Number.parseFloat(value);
      if (spec.min !== undefined && parsed < spec.min) return { ok: false, reason: `must be >= ${spec.min}` };
      if (spec.max !== undefined && parsed > spec.max) return { ok: false, reason: `must be <= ${spec.max}` };
      return { ok: true };
    }
    case "string":
      if (/[\n\r]/.test(value)) return { ok: false, reason: "must not contain line breaks" };
      return { ok: true };
  }
}

// Normalize a valid value into the format the INI template expects
export function normalizeSettingValue(spec: SettingSpec, value: string): string {
  if (spec.type === "float") return Number.parseFloat(value).toFixed(6);
  return value.trim();
}
