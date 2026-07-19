import type { CompanionConfig } from "../config.js";
import { log } from "../logger.js";

// Placeholder until the Discord status card milestone lands.
export async function startDiscordStatus(_config: CompanionConfig): Promise<() => void> {
  log.warn(">>> Discord status card is not implemented yet - coming in a later milestone");
  return () => {};
}
