import { createHmac, randomBytes, timingSafeEqual } from "node:crypto";
import type { StateStore } from "../state.js";

export const SESSION_COOKIE = "companion_session";
const SESSION_TTL_MS = 24 * 60 * 60 * 1000;
const MAX_FAILURES = 5;
const LOCKOUT_MS = 60_000;

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
  private readonly failures = new Map<string, { count: number; lockedUntil: number }>();

  constructor(
    private readonly secret: string,
    private readonly username: string,
    private readonly password: string,
  ) {}

  static async ensureSecret(state: StateStore): Promise<string> {
    let secret = state.get().sessionSecret;
    if (!secret) {
      secret = randomBytes(32).toString("hex");
      await state.update({ sessionSecret: secret });
    }
    return secret;
  }

  private sign(data: string): string {
    return createHmac("sha256", this.secret).update(data).digest("hex");
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
    const entry = this.failures.get(ip) ?? { count: 0, lockedUntil: 0 };
    if (entry.count >= MAX_FAILURES && entry.lockedUntil <= Date.now()) {
      entry.count = 0; // previous lockout expired - start a fresh window
    }
    entry.count += 1;
    if (entry.count >= MAX_FAILURES) {
      entry.lockedUntil = Date.now() + LOCKOUT_MS;
    }
    this.failures.set(ip, entry);
  }

  recordSuccess(ip: string): void {
    this.failures.delete(ip);
  }
}
