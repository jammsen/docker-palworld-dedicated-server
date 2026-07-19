import { readFile } from "node:fs/promises";

// The generated PalWorldSettings.ini contains the *effective* server name -
// including the boot-time ###RANDOM### substitution that only happens inside
// the servermanager subshell and never reaches the companion's environment.
export function parseServerName(iniContent: string): string | null {
  const match = /ServerName="([^"]*)"/.exec(iniContent);
  return match && match[1] !== undefined && match[1].length > 0 ? match[1] : null;
}

export async function readServerNameFromIni(iniPath: string): Promise<string | null> {
  try {
    return parseServerName(await readFile(iniPath, "utf8"));
  } catch {
    return null;
  }
}
