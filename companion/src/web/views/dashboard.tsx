import { formatDuration, formatGiB } from "../../discord/card.js";
import type { StatusSnapshot } from "../../metrics/collector.js";
import { Layout } from "./layout.js";

export interface DashboardPageProps {
  t: (key: string) => string;
  language: string;
  snapshot: StatusSnapshot;
  csrf: string;
}

function StatTile({ label, value }: { label: string; value: string }) {
  return (
    <div class="tile">
      <span class="tile-label">{label}</span>
      <span class="tile-value">{value}</span>
    </div>
  );
}

function UsageBar({ percent }: { percent: number }) {
  const clamped = Math.min(100, Math.max(0, percent));
  return (
    <div class="bar">
      <div class="bar-fill" style={`width: ${clamped}%`} />
    </div>
  );
}

export function DashboardPage({ t, language, snapshot, csrf }: DashboardPageProps) {
  const game = snapshot.game;
  const ramPercent = snapshot.ram.totalBytes > 0 ? (snapshot.ram.usedBytes / snapshot.ram.totalBytes) * 100 : 0;
  const pings = snapshot.players.map((p) => p.ping).filter((p) => Number.isFinite(p) && p >= 0);
  const avgPing = pings.length > 0 ? `${Math.round(pings.reduce((s, p) => s + p, 0) / pings.length)}ms` : "n/a";

  return (
    <Layout t={t} language={language} activeNav="dashboard" autoRefreshSeconds={10} csrf={csrf}>
      <h1>{snapshot.serverName}</h1>
      {game ? (
        <div>
          <div class="banner-row">
            <p class="status-banner online">🟢 {t("status.serverOnline")}</p>
            <form method="post" action="/actions/restart" class="inline" data-confirm={t("status.restartConfirm")}>
              <input type="hidden" name="_csrf" value={csrf} />
              <button type="submit" title={t("status.restartHint")}>
                🔄 {t("status.restart")}
              </button>
            </form>
          </div>
          <div class="tiles">
            <StatTile label={`⏱️ ${t("status.uptime")}`} value={formatDuration(game.uptime)} />
            <StatTile label={`👥 ${t("status.population")}`} value={`${game.currentplayernum} / ${game.maxplayernum}`} />
            <StatTile label={`📡 ${t("status.latency")}`} value={avgPing} />
            <StatTile label={`⚡ ${t("status.fps")}`} value={String(game.serverfps)} />
            <StatTile label={`📅 ${t("status.day")}`} value={String(game.days)} />
            <StatTile label={`🏕️ ${t("status.basecamps")}`} value={String(game.basecampnum ?? "-")} />
          </div>

          <h2>💾 {t("status.ram")}</h2>
          <p>
            {formatGiB(snapshot.ram.usedBytes)} / {formatGiB(snapshot.ram.totalBytes)}
          </p>
          <UsageBar percent={ramPercent} />

          {snapshot.cpuCorePercents.length > 0 ? (
            <div>
              <h2>⚙️ {t("status.cpu")}</h2>
              <div class="cores">
                {snapshot.cpuCorePercents.map((percent, index) => (
                  <div class="core-row">
                    <span class="core-label">
                      {t("status.core")} {index + 1}
                    </span>
                    <UsageBar percent={percent} />
                    <span class="core-percent">{percent}%</span>
                  </div>
                ))}
              </div>
            </div>
          ) : null}

          {snapshot.lastRestartAt !== null ? (
            <p>
              🔄 {t("status.lastRestart")}: {new Date(snapshot.lastRestartAt).toISOString().replace("T", " ").slice(0, 19)} UTC
            </p>
          ) : null}
        </div>
      ) : (
        <p class="status-banner starting">🟡 {t("status.serverStarting")}</p>
      )}
      <p class="hint">{t("status.refreshNote")}</p>
    </Layout>
  );
}
