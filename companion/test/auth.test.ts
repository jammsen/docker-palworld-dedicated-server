import { describe, expect, it } from "vitest";
import { AuthService } from "../src/web/auth.js";

const SECRET = "0123456789abcdef0123456789abcdef";

describe("AuthService", () => {
  it("accepts only the exact credentials", () => {
    const auth = new AuthService(SECRET, "admin", "hunter2");
    expect(auth.verifyLogin("admin", "hunter2")).toBe(true);
    expect(auth.verifyLogin("admin", "hunter3")).toBe(false);
    expect(auth.verifyLogin("root", "hunter2")).toBe(false);
    expect(auth.verifyLogin("", "")).toBe(false);
  });

  it("round-trips a session and rejects tampering", () => {
    const auth = new AuthService(SECRET, "admin", "pw");
    const session = auth.createSession();
    expect(auth.verifySession(session)).toBe(true);
    expect(auth.verifySession(undefined)).toBe(false);
    expect(auth.verifySession("garbage")).toBe(false);
    const [expiry, signature] = session.split(".");
    expect(auth.verifySession(`${Number(expiry) + 9999999}.${signature}`)).toBe(false);
  });

  it("rejects sessions signed with a different secret", () => {
    const authA = new AuthService(SECRET, "admin", "pw");
    const authB = new AuthService("another-secret-another-secret-12", "admin", "pw");
    expect(authB.verifySession(authA.createSession())).toBe(false);
  });

  it("issues and verifies CSRF tokens bound to the session", () => {
    const auth = new AuthService(SECRET, "admin", "pw");
    const session = auth.createSession();
    const token = auth.csrfToken(session);
    expect(auth.verifyCsrf(session, token)).toBe(true);
    expect(auth.verifyCsrf(session, "wrong")).toBe(false);
    expect(auth.verifyCsrf(auth.createSession() + "x", token)).toBe(false);
  });

  it("locks out an IP after repeated failures and recovers after the window", () => {
    const auth = new AuthService(SECRET, "admin", "pw");
    for (let i = 0; i < 5; i++) auth.recordFailure("1.2.3.4");
    expect(auth.isLockedOut("1.2.3.4")).toBe(true);
    expect(auth.isLockedOut("5.6.7.8")).toBe(false);
    auth.recordSuccess("1.2.3.4");
    expect(auth.isLockedOut("1.2.3.4")).toBe(false);
  });
});
