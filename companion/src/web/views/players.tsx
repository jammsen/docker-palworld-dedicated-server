import type { StatusSnapshot } from "../../metrics/collector.js";
import type { BanlistEntry } from "../../palworld/banlist.js";
import { platformFromUserId } from "../../palworld/platform.js";
import { Layout } from "./layout.js";

export interface PlayersPageProps {
  t: (key: string) => string;
  language: string;
  snapshot: StatusSnapshot;
  csrf: string;
  banlist: BanlistEntry[];
  actionResult?: "kicked" | "banned" | "unbanned" | "failed";
}

function ModerationForm({
  action,
  userid,
  label,
  confirmText,
  csrf,
  buttonClass = "btn-danger",
}: {
  action: string;
  userid: string;
  label: string;
  /** Omit to submit without a confirm dialog */
  confirmText?: string;
  csrf: string;
  buttonClass?: string;
}) {
  return (
    <form method="post" action={action} class="inline" data-confirm={confirmText}>
      <input type="hidden" name="_csrf" value={csrf} />
      <input type="hidden" name="userid" value={userid} />
      <button type="submit" class={buttonClass}>
        {label}
      </button>
    </form>
  );
}

export function PlayersPage({ t, language, snapshot, csrf, banlist, actionResult }: PlayersPageProps) {
  return (
    <Layout t={t} language={language} activeNav="players" csrf={csrf}>
      <h1>
        👥 {t("players.title")} ({snapshot.players.length})
      </h1>

      {actionResult === "failed" ? (
        <p class="status-banner error-banner">⚠️ {t("players.actionFailed")}</p>
      ) : actionResult ? (
        <p class="status-banner online">✅ {t(`players.${actionResult}`)}</p>
      ) : null}

      {snapshot.players.length === 0 ? (
        <p class="hint">{t("players.none")}</p>
      ) : (
        <table>
          <thead>
            <tr>
              <th>{t("players.name")}</th>
              <th>{t("players.account")}</th>
              <th>{t("players.platform")}</th>
              <th>{t("players.level")}</th>
              <th>{t("players.ping")}</th>
              <th>{t("players.buildings")}</th>
              <th>{t("players.actions")}</th>
            </tr>
          </thead>
          <tbody>
            {snapshot.players.map((player) => (
              <tr>
                <td>{player.name}</td>
                <td>{player.accountName}</td>
                <td>{platformFromUserId(player.userId)}</td>
                <td>{player.level}</td>
                <td>{Math.round(player.ping)}ms</td>
                <td>{player.building_count}</td>
                <td class="actions-cell">
                  <ModerationForm
                    action="/players/kick"
                    userid={player.userId}
                    label={t("players.kick")}
                    confirmText={`${t("players.kickConfirm")} ${player.name}?`}
                    csrf={csrf}
                  />
                  <ModerationForm
                    action="/players/ban"
                    userid={player.userId}
                    label={t("players.ban")}
                    confirmText={`${t("players.banConfirm")} ${player.name}?`}
                    csrf={csrf}
                  />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}

      <h2>🚫 {t("players.banlist")}</h2>
      {banlist.length === 0 ? (
        <p class="hint">{t("players.banlistEmpty")}</p>
      ) : (
        <table>
          <tbody>
            {banlist.map((entry) => (
              <tr>
                <td>
                  <code>{entry.raw}</code>
                </td>
                <td>
                  <ModerationForm action="/players/unban" userid={entry.userid} label={t("players.unban")} csrf={csrf} buttonClass="linklike" />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </Layout>
  );
}
