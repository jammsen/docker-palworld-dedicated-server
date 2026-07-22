import { createHmac, randomBytes, timingSafeEqual } from "node:crypto";
import type { StateStore } from "../state.js";

export const SESSION_COOKIE = "companion_session";
const SESSION_TTL_MS = 24 * 60 * 60 * 1000;
const MAX_FAILURES = 5;
const LOCKOUT_MS = 60_000;
// Bounds for the failure map so distributed attempts cannot grow it forever
const FAILURE_TTL_MS = 15 * 60_000;
const MAX_TRACKED_IPS = 10_000;

function safeEqual(a: string, b: string): boolean {
  const bufA = Buffer.from(a);
  const bufB = Buffer.from(b);
  if (bufA.length !== bufB.length) return false;
  return timingSafeEqual(bufA, bufB);
}

// Stateless HMAC-signed sessions: cookie = "<expiryMillis>.<hmac(expiry)>".
// The signing secret is generated once and persisted on the game volume,
// so sessions survive companion and container restarts.
export class AuthService {
  private readonly failures = new Map<string, { count: number; lockedUntil: number; lastFailureAt: number }>();
  private readonly signingKey: Buffer;

  constructor(
    secret: string,
    private readonly username: string,
    private readonly password: string,
  ) {
    // Bind the signing key to the credentials so rotating PANEL_PASSWORD
    // (or PANEL_USERNAME) revokes all previously issued sessions.
    this.signingKey = createHmac("sha256", secret).update(`${username}:${password}`).digest();
  }

  static async ensureSecret(state: StateStore): Promise<string> {
    let secret = state.get().sessionSecret;
    if (!secret) {
      secret = randomBytes(32).toString("hex");
      await state.update({ sessionSecret: secret });
    }
    return secret;
  }

  private sign(data: string): string {
    return createHmac("sha256", this.signingKey).update(data).digest("hex");
  }

  verifyLogin(username: string, password: string): boolean {
    // Evaluate both comparisons to keep timing independent of which one fails
    const userOk = safeEqual(username, this.username);
    const passOk = safeEqual(password, this.password);
    return userOk && passOk;
  }

  createSession(): string {
    const expiry = Date.now() + SESSION_TTL_MS;
    return `${expiry}.${this.sign(String(expiry))}`;
  }

  verifySession(cookie: string | undefined): boolean {
    if (!cookie) return false;
    const [expiryRaw, signature] = cookie.split(".");
    if (!expiryRaw || !signature) return false;
    const expiry = Number.parseInt(expiryRaw, 10);
    if (!Number.isFinite(expiry) || expiry < Date.now()) return false;
    return safeEqual(signature, this.sign(expiryRaw));
  }

  csrfToken(sessionCookie: string): string {
    return this.sign(`csrf:${sessionCookie}`);
  }

  verifyCsrf(sessionCookie: string | undefined, token: string | undefined): boolean {
    if (!sessionCookie || !token) return false;
    return safeEqual(token, this.csrfToken(sessionCookie));
  }

  isLockedOut(ip: string): boolean {
    const entry = this.failures.get(ip);
    return entry !== undefined && entry.count >= MAX_FAILURES && entry.lockedUntil > Date.now();
  }

  recordFailure(ip: string): void {
    this.pruneFailures();
    const entry = this.failures.get(ip) ?? { count: 0, lockedUntil: 0, lastFailureAt: 0 };
    if (entry.count >= MAX_FAILURES && entry.lockedUntil <= Date.now()) {
      entry.count = 0; // previous lockout expired - start a fresh window
    }
    entry.count += 1;
    entry.lastFailureAt = Date.now();
    if (entry.count >= MAX_FAILURES) {
      entry.lockedUntil = Date.now() + LOCKOUT_MS;
    }
    this.failures.set(ip, entry);
  }

  // Keep the failure map bounded under distributed brute-force: drop entries
  // that went quiet past the TTL, then evict oldest-first (Map preserves
  // insertion order) if a flood is still over the cap.
  private pruneFailures(): void {
    if (this.failures.size < MAX_TRACKED_IPS) return;
    const now = Date.now();
    for (const [ip, entry] of this.failures) {
      if (now - entry.lastFailureAt > FAILURE_TTL_MS && entry.lockedUntil <= now) {
        this.failures.delete(ip);
      }
    }
    while (this.failures.size >= MAX_TRACKED_IPS) {
      const oldest = this.failures.keys().next().value;
      if (oldest === undefined) break;
      this.failures.delete(oldest);
    }
  }

  recordSuccess(ip: string): void {
    this.failures.delete(ip);
  }
}
