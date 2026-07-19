import { Hono } from "hono";
import type { CompanionConfig } from "../config.js";

export interface AppEnv {
  Variables: Record<string, never>;
}

export function createApp(config: CompanionConfig, version: string): Hono<AppEnv> {
  const app = new Hono<AppEnv>();

  app.use("*", async (c, next) => {
    c.header("Cache-Control", "no-store");
    c.header("X-Content-Type-Options", "nosniff");
    await next();
  });

  // Unauthenticated liveness endpoint for CI smoke tests and user monitoring
  app.get("/api/health", (c) =>
    c.json({
      status: "ok",
      version,
      panel: config.panel !== null,
      discord: config.discord !== null,
    }),
  );

  app.get("/", (c) => c.text(`palworld-companion ${version} - web panel UI arrives in a later milestone`));

  return app;
}
