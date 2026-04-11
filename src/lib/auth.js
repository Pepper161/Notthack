import { randomBytes } from "node:crypto";

const USERS = [
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
  {
    email: "affairs@uni.edu",
    password: "password123",
    role: "issuer",
    actorId: "issuer-affairs",
    displayName: "Student Affairs Office",
  },
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
  {
    email: "cafe-x@merchant.uni.edu",
    password: "password123",
    role: "merchant",
    merchantId: "CAF-X",
    displayName: "Campus Cafeteria X",
  },
  {
    email: "audit@uni.edu",
    password: "password123",
    role: "auditor",
    actorId: "auditor-1",
    displayName: "Finance & Compliance",
  },
];

const sessions = new Map();

function sanitize(user) {
  const { password: _password, ...rest } = user;
  return rest;
}

function findUser(email, password) {
  if (typeof email !== "string" || typeof password !== "string") return null;
  const lookup = email.trim().toLowerCase();
  return (
    USERS.find(
      (user) => user.email.toLowerCase() === lookup && user.password === password,
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

function requireRole(...allowed) {
  const allowedSet = new Set(allowed);
  return (req, res, next) => {
    const user = req.user ?? getUserFromRequest(req);
    if (!user) {
      return res.status(401).json({
        ok: false,
        error: "Authentication required",
      });
    }
    if (!allowedSet.has(user.role)) {
      return res.status(403).json({
        ok: false,
        error: `Forbidden — this endpoint is only available to: ${[...allowedSet].join(", ")}`,
        yourRole: user.role,
      });
    }
    req.user = user;
    return next();
  };
}

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
