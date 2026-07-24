// Drift guard: the settings schema, the gameserver repo's includes/config.sh
// ENVSUBST_SELECTORS and its Dockerfile ENV defaults must stay in sync. The
// gameserver repo is found either as the parent dir (monorepo layout) or as a
// sibling checkout (sidecar layout); skipped when neither is present (e.g.
// inside the Docker build stage or a lone CI checkout).
import { existsSync, readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import { settingsSchema } from "../src/settings/schema.js";

const GAMESERVER_ROOT = ["..", "../docker-palworld-dedicated-server"].find((root) =>
  existsSync(`${root}/includes/config.sh`),
);
const CONFIG_SH = `${GAMESERVER_ROOT}/includes/config.sh`;
const DOCKERFILE = `${GAMESERVER_ROOT}/Dockerfile`;
const repoAvailable = GAMESERVER_ROOT !== undefined && existsSync(DOCKERFILE);

// Engine.ini setting - handled separately from ENVSUBST_SELECTORS in config.sh
const NON_SELECTOR_KEYS = new Set(["NETSERVERMAXTICKRATE"]);

describe.skipIf(!repoAvailable)("schema drift guard", () => {
  it("covers exactly the keys in ENVSUBST_SELECTORS", () => {
    const configSh = readFileSync(CONFIG_SH, "utf8");
    const selectorBlock = /ENVSUBST_SELECTORS='([^']+)'/.exec(configSh);
    expect(selectorBlock).not.toBeNull();
    const selectorKeys = new Set([...selectorBlock![1]!.matchAll(/\$([A-Z0-9_]+)/g)].map((m) => m[1]!));
    const schemaKeys = new Set(settingsSchema.map((spec) => spec.key));

    const missingInSchema = [...selectorKeys].filter((key) => !schemaKeys.has(key));
    expect(missingInSchema, "keys in config.sh ENVSUBST_SELECTORS but missing in schema.ts").toEqual([]);

    const extraInSchema = [...schemaKeys].filter((key) => !selectorKeys.has(key) && !NON_SELECTOR_KEYS.has(key));
    expect(extraInSchema, "keys in schema.ts but missing in config.sh ENVSUBST_SELECTORS").toEqual([]);
  });

  it("matches the Dockerfile ENV defaults", () => {
    const dockerfile = readFileSync(DOCKERFILE, "utf8");
    const mismatches: string[] = [];
    for (const spec of settingsSchema) {
      // The last ENV line has no trailing backslash
      const match = new RegExp(`^\\s+${spec.key}=("?)(.*?)\\1(?: \\\\)?$`, "m").exec(dockerfile);
      if (!match) {
        mismatches.push(`${spec.key}: not found in Dockerfile ENV block`);
        continue;
      }
      if (match[2] !== spec.default) {
        mismatches.push(`${spec.key}: schema default '${spec.default}' != Dockerfile '${match[2]}'`);
      }
    }
    expect(mismatches).toEqual([]);
  });
});
