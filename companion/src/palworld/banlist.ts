export interface BanlistEntry {
  /** The id POST /unban expects, e.g. "steam_76561197961348531" */
  userid: string;
  /** The full line as written by the game, e.g. "steam_...,4DCC09FB..." */
  raw: string;
}

// banlist.txt lines are "<userid>,<playerUID>" (comma-separated); only the
// first field is a valid target for POST /unban.
export function parseBanlist(content: string): BanlistEntry[] {
  return content
    .split("\n")
    .map((line) => line.trim())
    .filter((line) => line.length > 0)
    .map((raw) => ({ userid: raw.split(",")[0]!.trim(), raw }))
    .filter((entry) => entry.userid.length > 0);
}
