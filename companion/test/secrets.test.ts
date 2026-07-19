import { mkdtemp } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { describe, expect, it } from "vitest";
import { SettingsStore } from "../src/settings/store.js";
import { SettingsPage } from "../src/web/views/settings.js";

const SECRET_ADMIN = "super-secret-admin-pw";
const SECRET_SERVER = "super-secret-server-pw";

async function makeStore() {
  const dir = await mkdtemp(join(tmpdir(), "companion-secrets-"));
  return new SettingsStore(dir, {
    ADMIN_PASSWORD: SECRET_ADMIN,
    SERVER_PASSWORD: SECRET_SERVER,
  });
}

describe("secret settings never leak", () => {
  it("effectiveSettings redacts secret values", async () => {
    const store = await makeStore();
    const serialized = JSON.stringify(await store.effectiveSettings());
    expect(serialized).not.toContain(SECRET_ADMIN);
    expect(serialized).not.toContain(SECRET_SERVER);
  });

  it("the rendered settings page contains no secret values", async () => {
    const store = await makeStore();
    const html = String(
      SettingsPage({
        t: (key) => key,
        language: "en",
        csrf: "token",
        settings: await store.effectiveSettings(),
        readOnly: false,
        restartPending: false,
      }),
    );
    expect(html).not.toContain(SECRET_ADMIN);
    expect(html).not.toContain(SECRET_SERVER);
    expect(html).toContain("ADMIN_PASSWORD"); // row still shown, just masked
  });

  it("the .env export contains no secret values", async () => {
    const store = await makeStore();
    const exported = await store.exportEnv();
    expect(exported).not.toContain(SECRET_ADMIN);
    expect(exported).not.toContain(SECRET_SERVER);
  });
});
