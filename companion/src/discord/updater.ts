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
  let currentTick: Promise<void> = Promise.resolve();

  const tick = async () => {
    if (inFlight || stopped) return;
    inFlight = true;
    try {
      const snapshot = await collector.collect();
      const cardState: CardState = snapshot.serverUp ? "online" : "starting";
      const serverName = snapshot.serverName;
      await transport.publish(
        buildStatusCard(snapshot, cardState, serverName, {
          platformEmoji: discord.platformEmoji,
          eventEmoji: discord.eventEmoji,
          eventAmount: discord.eventAmount,
        }),
      );
    } catch (error) {
      log.warn(`>>> Discord status update failed: ${String(error)}`);
    } finally {
      inFlight = false;
    }
  };

  // Capture the promise only when a tick actually starts, so stop() awaits
  // the real in-flight publish and not an instantly-resolved guard return.
  const scheduleTick = () => {
    if (!inFlight && !stopped) currentTick = tick();
  };

  log.info(`>>> Discord status card enabled (update interval: ${discord.updateIntervalSeconds}s)`);
  scheduleTick();
  const timer = setInterval(scheduleTick, discord.updateIntervalSeconds * 1000);

  return async () => {
    stopped = true;
    clearInterval(timer);
    await currentTick; // never rejects - tick() catches internally
    try {
      // Pick up the shell's 'stopping' event written just before our SIGTERM,
      // so the final card shows the complete log including the shutdown itself
      const snapshot = await collector.refreshEventsOnly();
      await transport.publish(
        buildStatusCard(snapshot, "offline", snapshot?.serverName ?? config.serverName, {
          platformEmoji: discord.platformEmoji,
          eventEmoji: discord.eventEmoji,
          eventAmount: discord.eventAmount,
        }),
      );
      log.info(">>> Discord status card set to offline");
    } catch (error) {
      log.warn(`>>> Final Discord offline update failed: ${String(error)}`);
    }
  };
}
