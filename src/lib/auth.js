import { randomBytes } from "node:crypto";

/**
 * Role-based authentication for NourishChain.
 *
 * This is an in-memory user directory + session store. For a real deployment
 * you would replace this with a database + password hashing (bcrypt/argon2)
 * + JWT or signed cookies. For the hackathon demo, every account is
 * pre-seeded and tokens live in-process (they reset when the server restarts).
 *
 * Each account is bound to a role, and (where applicable) to a specific
 * studentId or merchantId. The backend uses those bindings as the source of
 * truth — clients can NOT change their own merchantId / studentId by sending
 * values in the request body. That fixes the loophole where any user could
 * pretend to be any role.
 */

const USERS = [
  // ─── Students ─────────────────────────────────────────────────────────────
  {
    email: "aisha@student.uni.edu",
    password: "password123",
    role: "student",
    studentId: "STU-1001",
    displayName: "Aisha K.",
  },
  {
    email: "ravi@student.uni.edu",
    password: "password123",
    role: "student",
    studentId: "STU-1002",
    displayName: "Ravi M.",
  },

  // ─── Issuer (Student Affairs) ────────────────────────────────────────────
  {
    email: "affairs@uni.edu",
    password: "password123",
    role: "issuer",
    actorId: "issuer-affairs",
    displayName: "Student Affairs Office",
  },

  // ─── Merchants (each cafeteria is its own account) ───────────────────────
  {
    email: "cafe-a@merchant.uni.edu",
    password: "password123",
    role: "merchant",
    merchantId: "CAF-A",
    displayName: "Campus Cafeteria A",
  },
  {
    email: "cafe-b@merchant.uni.edu",
    password: "password123",
    role: "merchant",
    merchantId: "CAF-B",
    displayName: "Campus Cafeteria B",
  },

  // ─── Auditor (Finance & Compliance) ──────────────────────────────────────
  {
    email: "audit@uni.edu",
    password: "password123",
    role: "auditor",
    actorId: "auditor-1",
    displayName: "Finance & Compliance",
  },
];

/** token -> public profile (everything in USERS except `password`). */
const sessions = new Map();

function sanitize(user) {
  const { password: _pw, ...rest } = user;
  return rest;
}

function findUser(email, password) {
  if (typeof email !== "string" || typeof password !== "string") return null;
  const lookup = email.trim().toLowerCase();
  return (
    USERS.find(
      (u) => u.email.toLowerCase() === lookup && u.password === password,
    ) ?? null
  );
}

function createToken() {
  return randomBytes(32).toString("hex");
}

function login(email, password) {
  const user = findUser(email, password);
  if (!user) return null;
  const token = createToken();
  const profile = sanitize(user);
  sessions.set(token, profile);
  return { token, user: profile };
}

function logout(token) {
  if (!token) return false;
  return sessions.delete(token);
}

function extractToken(req) {
  const header = req.headers?.authorization ?? "";
  if (header.startsWith("Bearer ")) return header.slice(7).trim();
  return null;
}

function getUserFromRequest(req) {
  const token = extractToken(req);
  if (!token) return null;
  return sessions.get(token) ?? null;
}

/** Attach req.user if a valid bearer token is provided; 401 otherwise. */
function requireAuth(req, res, next) {
  const user = getUserFromRequest(req);
  if (!user) {
    return res.status(401).json({
      ok: false,
      error: "Authentication required",
    });
  }
  req.user = user;
  return next();
}

/**
 * Require that the authenticated user's role is in the allow-list.
 * Must be chained AFTER requireAuth (or used alongside it).
 */
function requireRole(...allowed) {
  const set = new Set(allowed);
  return (req, res, next) => {
    const user = req.user ?? getUserFromRequest(req);
    if (!user) {
      return res.status(401).json({
        ok: false,
        error: "Authentication required",
      });
    }
    if (!set.has(user.role)) {
      return res.status(403).json({
        ok: false,
        error: `Forbidden — this endpoint is only available to: ${[...set].join(", ")}`,
        yourRole: user.role,
      });
    }
    req.user = user;
    return next();
  };
}

/** List of accounts (without passwords) — handy for debugging / a /whoami list. */
function listAccounts() {
  return USERS.map(sanitize);
}

export {
  login,
  logout,
  requireAuth,
  requireRole,
  getUserFromRequest,
  listAccounts,
};
