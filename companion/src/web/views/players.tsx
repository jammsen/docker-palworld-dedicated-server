import type { StatusSnapshot } from "../../metrics/collector.js";
import { Layout } from "./layout.js";

export interface PlayersPageProps {
  t: (key: string) => string;
  language: string;
  snapshot: StatusSnapshot;
  csrf: string;
}

export function PlayersPage({ t, language, snapshot, csrf }: PlayersPageProps) {
  return (
    <Layout t={t} language={language} activeNav="players" autoRefreshSeconds={15} csrf={csrf}>
      <h1>
        👥 {t("players.title")} ({snapshot.players.length})
      </h1>
      {snapshot.players.length === 0 ? (
        <p class="hint">{t("players.none")}</p>
      ) : (
        <table>
          <thead>
            <tr>
              <th>{t("players.name")}</th>
              <th>{t("players.account")}</th>
              <th>{t("players.level")}</th>
              <th>{t("players.ping")}</th>
              <th>{t("players.buildings")}</th>
            </tr>
          </thead>
          <tbody>
            {snapshot.players.map((player) => (
              <tr>
                <td>{player.name}</td>
                <td>{player.accountName}</td>
                <td>{player.level}</td>
                <td>{Math.round(player.ping)}ms</td>
                <td>{player.building_count}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </Layout>
  );
}
