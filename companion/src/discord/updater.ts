import type { CompanionConfig } from "../config.js";
import { log } from "../logger.js";
import type { MetricsCollector } from "../metrics/collector.js";
import type { StateStore } from "../state.js";
import { buildStatusCard, type CardState } from "./card.js";
import type { StatusTransport } from "./transport.js";
import { WebhookTransport } from "./webhook.js";

export interface DiscordStatusDeps {
  collector: MetricsCollector;
  state: StateStore;
  transport?: StatusTransport;
}

// Interval loop: collect a snapshot, render the card, publish (create-or-edit).
// Returns a stop function that publishes a final "offline" card.
export async function startDiscordStatus(config: CompanionConfig, deps: DiscordStatusDeps): Promise<() => Promise<void>> {
  const discord = config.discord;
  if (!discord) throw new Error("startDiscordStatus called without Discord config");

  const { collector, state } = deps;
  const transport =
    deps.transport ??
    new WebhookTransport({
      webhookUrl: discord.webhookUrl,
      getMessageId: () => state.get().discordMessageId,
      setMessageId: (id) => state.update({ discordMessageId: id }),
    });

  let inFlight = false;
  let stopped = false;

  const tick = async () => {
    if (inFlight || stopped) return;
    inFlight = true;
    try {
      const snapshot = await collector.collect();
      const cardState: CardState = snapshot.serverUp ? "online" : "starting";
      const serverName = snapshot.serverName;
      await transport.publish(buildStatusCard(snapshot, cardState, serverName, discord.platformEmoji));
    } catch (error) {
      log.warn(`>>> Discord status update failed: ${String(error)}`);
    } finally {
      inFlight = false;
    }
  };

  log.info(`>>> Discord status card enabled (update interval: ${discord.updateIntervalSeconds}s)`);
  void tick();
  const timer = setInterval(() => void tick(), discord.updateIntervalSeconds * 1000);

  return async () => {
    stopped = true;
    clearInterval(timer);
    try {
      const snapshot = collector.latest();
      await transport.publish(buildStatusCard(snapshot, "offline", snapshot?.serverName ?? config.serverName, discord.platformEmoji));
      log.info(">>> Discord status card set to offline");
    } catch (error) {
      log.warn(`>>> Final Discord offline update failed: ${String(error)}`);
    }
  };
}
