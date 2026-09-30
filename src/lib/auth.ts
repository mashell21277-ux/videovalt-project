import { SignJWT, jwtVerify } from "jose";
import { cookies } from "next/headers";
import { NextRequest } from "next/server";

const COOKIE_NAME = "admin_session";
const SESSION_DURATION = 60 * 60 * 24 * 7; // 7 days

function getSecret() {
  const secret = process.env.JWT_SECRET;
  if (!secret) throw new Error("JWT_SECRET is not configured");
  return new TextEncoder().encode(secret);
}

export async function verifyAdminPassword(password: string): Promise<boolean> {
  const adminPassword = process.env.ADMIN_PASSWORD;
  if (!adminPassword) return false;
  return password === adminPassword;
}

export async function createSession(): Promise<string> {
  return new SignJWT({ role: "admin" })
    .setProtectedHeader({ alg: "HS256" })
    .setIssuedAt()
    .setExpirationTime(`${SESSION_DURATION}s`)
    .sign(getSecret());
}

export async function verifySession(token: string): Promise<boolean> {
  try {
    const { payload } = await jwtVerify(token, getSecret());
    return payload.role === "admin";
  } catch {
    return false;
  }
}

function extractToken(request?: NextRequest, cookieToken?: string): string | null {
  if (cookieToken) return cookieToken;

  if (request) {
    const authHeader = request.headers.get("authorization");
    if (authHeader?.startsWith("Bearer ")) {
      return authHeader.slice(7);
    }
    return request.cookies.get(COOKIE_NAME)?.value ?? null;
  }

  return null;
}

export async function isAdmin(request?: NextRequest): Promise<boolean> {
  let token: string | null = null;

  if (request) {
    token = extractToken(request);
  } else {
    const cookieStore = await cookies();
    token = cookieStore.get(COOKIE_NAME)?.value ?? null;
  }

  if (!token) return false;
  return verifySession(token);
}

export { COOKIE_NAME, SESSION_DURATION };
