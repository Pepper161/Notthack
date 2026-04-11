import express from "express";
import QRCode from "qrcode";
import path from "node:path";
import { fileURLToPath } from "node:url";
import {
  deriveVoucherHash,
  applyDemoReset,
  getAuditHistory,
  getState,
  getStudentPass,
  getVoucher,
  issueVoucher,
  logOverride,
  redeemVoucher,
  revokeVoucher,
  verifyVoucher,
} from "./lib/state.js";
import {
  describeOffchainIssuance,
  getLedgerStatus,
  recordOverrideLogged,
  recordVoucherRedeemed,
  recordVoucherRevoked,
} from "./lib/solana-ledger.js";
import {
  login as authLogin,
  logout as authLogout,
  requireAuth,
  requireRole,
  listAccounts,
} from "./lib/auth.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const port = process.env.PORT ? Number(process.env.PORT) : 3000;

app.use(express.json());
app.use(express.static(path.join(__dirname, "..", "public")));

function sendJsonError(res, status, message, extra = {}) {
  return res.status(status).json({
    ok: false,
    error: message,
    ...extra,
  });
}

function getChainState(voucher) {
  if (voucher.isRedeemed) return "redeemed";
  if (voucher.isRevoked) return "revoked";
  return "active";
}

function serializeVoucher(state, voucher) {
  const student = state.students[voucher.studentId] ?? null;

  return {
    voucherId: voucher.voucherId,
    studentId: voucher.studentId,
    studentName: student?.displayName ?? voucher.studentId,
    label: voucher.displayLabel,
    amountLabel: voucher.amountLabel,
    state: voucher.onChainState,
    issuedAt: voucher.issuedAt,
    revokedAt: voucher.revokedAt,
    redeemedAt: voucher.redeemedAt,
    merchantId: voucher.redeemedBy ?? null,
    checkpoint: voucher.redemptionCheckpointId ?? voucher.lastCheckpointId ?? null,
    voucherHash: deriveVoucherHash(voucher),
  };
}

function serializeAuditEvent(event) {
  const state = getState();
  const voucher = event.voucherId ? state.vouchers[event.voucherId] : null;
  const ledgerStatus = getLedgerStatus();

  return {
    eventId: event.eventId,
    voucherId: event.voucherId,
    type: event.type,
    timestamp: event.at,
    checkpoint: event.checkpointId ?? event.relatedCheckpointId ?? null,
    actorType: event.actorType,
    actorId: event.actorId,
    merchantId: event.actorType === "merchant" ? event.actorId : voucher?.redeemedBy ?? null,
    studentId: voucher?.studentId ?? null,
    reason: event.reason ?? null,
    reasonCode: event.reason ?? null,
    message:
      event.note ??
      event.reason ??
      event.details?.reason ??
      event.type.replaceAll("_", " "),
    txSignature: null,
    explorerUrl: null,
    cluster: ledgerStatus.cluster,
  };
}

function buildBootstrapPayload() {
  const state = getState();
  const vouchers = Object.values(state.vouchers).map((voucherRecord) => {
    const summary = getVoucher(voucherRecord.voucherId);
    return serializeVoucher(state, summary);
  });

  const students = Object.values(state.students);
  const merchants = Object.values(state.merchants);
  const auditEvents = getAuditHistory().map(serializeAuditEvent).reverse();

  const defaultVoucher = vouchers[0] ?? null;
  const selectedStudentVoucher = defaultVoucher
    ? {
        voucherId: defaultVoucher.voucherId,
        studentId: defaultVoucher.studentId,
        studentName: defaultVoucher.studentName,
        label: defaultVoucher.label,
        status: defaultVoucher.state,
      }
    : null;

  return {
    ok: true,
    message: "Bootstrap loaded",
    defaultMerchantId:
      merchants.find((merchant) => merchant.approved)?.merchantId ?? merchants[0]?.merchantId ?? null,
    defaultStudentId: students[0]?.studentId ?? null,
    defaultVoucherId: defaultVoucher?.voucherId ?? null,
    merchants,
    students,
    vouchers,
    selectedStudentVoucher,
    auditEvents,
  };
}

function mapVerifyResult(result) {
  const voucher = result.voucher
    ? {
        voucherId: result.voucher.voucherId,
        state: result.voucher.onChainState,
      }
    : null;

  return {
    ok: result.ok,
    code: result.code,
    status: result.code,
    reason: result.reason,
    title:
      result.code === "valid"
        ? "Voucher valid"
        : result.code === "already_redeemed"
          ? "Already redeemed"
          : result.code === "revoked"
            ? "Voucher revoked"
            : result.code === "merchant_not_approved"
              ? "Merchant not approved"
              : "Unknown voucher",
    message: result.reason,
    voucherId: voucher?.voucherId ?? null,
    voucher,
  };
}

function mapRedeemResult(result) {
  const onChain = result.onChain ?? null;
  return {
    ok: result.ok,
    code: result.code,
    status: result.code,
    reason: result.reason,
    title: result.ok ? "Voucher redeemed" : "Redemption blocked",
    message: result.reason,
    voucherId: result.voucher?.voucherId ?? null,
    checkpointRef: result.checkpointId ?? null,
    voucher: result.voucher ?? null,
    onChain: onChain ?? (result.ok
      ? {
          signature: null,
          explorerUrl: null,
          cluster: getLedgerStatus().cluster,
          checkpointRef: result.checkpointId ?? null,
        }
      : null),
  };
}

async function sendPassSvg(res, qrPayload) {
  const svg = await QRCode.toString(qrPayload, {
    type: "svg",
    errorCorrectionLevel: "M",
    margin: 1,
    width: 220,
  });
  return res.type("image/svg+xml").send(svg);
}

app.get("/api/health", (_req, res) => {
  res.json({
    ok: true,
    service: "bga-university-hardship-voucher-demo",
  });
});

app.post("/api/auth/login", (req, res) => {
  const { email, password } = req.body ?? {};
  if (!email || !password) {
    return sendJsonError(res, 400, "email and password are required");
  }

  const result = authLogin(email, password);
  if (!result) {
    return sendJsonError(res, 401, "Invalid email or password");
  }

  return res.json({
    ok: true,
    token: result.token,
    user: result.user,
  });
});

app.post("/api/auth/logout", requireAuth, (req, res) => {
  const header = req.headers.authorization ?? "";
  const token = header.startsWith("Bearer ") ? header.slice(7).trim() : null;
  authLogout(token);
  return res.json({ ok: true });
});

app.get("/api/auth/me", requireAuth, (req, res) => {
  return res.json({ ok: true, user: req.user });
});

app.get("/api/auth/accounts", (_req, res) => {
  return res.json({ ok: true, accounts: listAccounts() });
});

app.get("/api/bootstrap", requireAuth, (_req, res) => {
  res.json(buildBootstrapPayload());
});

app.post("/api/reset", requireAuth, requireRole("issuer"), (_req, res) => {
  applyDemoReset();
  res.json(buildBootstrapPayload());
});

app.post("/api/merchant/verify", requireAuth, requireRole("merchant"), (req, res) => {
  const { voucherId } = req.body ?? {};
  const merchantId = req.user.merchantId;
  if (!voucherId) {
    return sendJsonError(res, 400, "voucherId is required");
  }
  if (!merchantId) {
    return sendJsonError(res, 403, "Your account is not bound to a merchant");
  }

  const result = verifyVoucher({ merchantId, voucherId });
  const payload = mapVerifyResult(result);

  if (result.code === "merchant_not_approved") {
    return res.status(403).json(payload);
  }

  if (result.code === "unknown_voucher") {
    return res.status(404).json(payload);
  }

  return res.json(payload);
});

app.post("/api/merchant/redeem", requireAuth, requireRole("merchant"), async (req, res) => {
  const { voucherId } = req.body ?? {};
  const merchantId = req.user.merchantId;
  if (!voucherId) {
    return sendJsonError(res, 400, "voucherId is required");
  }
  if (!merchantId) {
    return sendJsonError(res, 403, "Your account is not bound to a merchant");
  }

  const result = redeemVoucher({ merchantId, voucherId, actorId: merchantId });
  const onChain = result.ok
    ? await recordVoucherRedeemed({
        voucherId,
        studentId: result.voucher?.studentId ?? null,
        programId: result.voucher?.programId ?? null,
        actorId: merchantId,
        checkpointRef: result.checkpointId ?? null,
        reference: result.voucher?.studentId ?? "",
      })
    : null;
  const payload = mapRedeemResult(result);
  if (onChain) {
    payload.onChain = onChain;
  }

  if (result.code === "merchant_not_approved") {
    return res.status(403).json(payload);
  }

  if (result.code === "unknown_voucher") {
    return res.status(404).json(payload);
  }

  if (!result.ok) {
    return res.status(409).json(payload);
  }

  return res.json(payload);
});

app.post("/api/issuer/issue", requireAuth, requireRole("issuer"), async (req, res) => {
  const { voucherId, studentId, note } = req.body ?? {};
  const actorId = req.user.actorId ?? req.user.email ?? "issuer";
  if (!studentId) {
    return sendJsonError(res, 400, "studentId is required");
  }

  try {
    const voucher = issueVoucher({ voucherId, studentId, actorId, note });
    const onChain = await describeOffchainIssuance({
      voucherId: voucher.voucherId,
      actorId: actorId ?? "staff",
      studentId: voucher.studentId,
      programId: voucher.programId,
    });
    return res.status(201).json({
      ok: true,
      message: `Voucher issued for ${studentId}`,
      voucherId: voucher.voucherId,
      voucher: {
        voucherId: voucher.voucherId,
        studentId: voucher.studentId,
        state: voucher.onChainState,
        checkpoint: voucher.redemptionCheckpointId,
      },
      onChain,
    });
  } catch (error) {
    return sendJsonError(res, 400, error instanceof Error ? error.message : String(error));
  }
});

app.post("/api/issuer/revoke", requireAuth, requireRole("issuer"), async (req, res) => {
  const { voucherId, reasonCode } = req.body ?? {};
  const actorId = req.user.actorId ?? req.user.email ?? "issuer";
  if (!voucherId) {
    return sendJsonError(res, 400, "voucherId is required");
  }

  try {
    const voucher = revokeVoucher({ voucherId, actorId, reason: reasonCode });
    const onChain = await recordVoucherRevoked({
      voucherId,
      studentId: voucher.studentId,
      programId: voucher.programId,
      actorId: actorId ?? "staff",
      checkpointRef: voucher.redemptionCheckpointId ?? null,
      reference: reasonCode ?? "",
    });
    return res.json({
      ok: true,
      message: `Voucher ${voucherId} revoked`,
      voucherId,
      voucher: {
        voucherId: voucher.voucherId,
        state: voucher.onChainState,
      },
      onChain,
    });
  } catch (error) {
    return sendJsonError(res, 400, error instanceof Error ? error.message : String(error));
  }
});

app.post("/api/issuer/override", requireAuth, requireRole("issuer"), async (req, res) => {
  const { voucherId, overrideReason } = req.body ?? {};
  const actorId = req.user.actorId ?? req.user.email ?? "issuer";
  if (!voucherId) {
    return sendJsonError(res, 400, "voucherId is required");
  }

  try {
    const result = logOverride({ voucherId, actorId, reason: overrideReason });
    const onChain = await recordOverrideLogged({
      voucherId,
      studentId: result.voucher?.studentId ?? null,
      programId: result.voucher?.programId ?? null,
      actorId: actorId ?? "staff",
      checkpointRef: result.checkpointId,
      reference: result.overrideEventHash,
    });
    return res.json({
      ok: true,
      message: `Override logged for ${voucherId}`,
      status: "override_logged",
      voucherId,
      checkpointRef: result.checkpointId,
      overrideEventHash: result.overrideEventHash,
      onChain,
    });
  } catch (error) {
    return sendJsonError(res, 400, error instanceof Error ? error.message : String(error));
  }
});

app.get("/api/student/:studentId/voucher", requireAuth, requireRole("student"), (req, res) => {
  const requested = req.params.studentId;
  const authStudentId = req.user.studentId;
  if (!authStudentId) {
    return sendJsonError(res, 403, "Your account is not bound to a student record");
  }
  if (requested !== "me" && requested !== authStudentId) {
    return sendJsonError(res, 403, "You may only view your own voucher");
  }

  const pass = getStudentPass(authStudentId);
  if (!pass) {
    return sendJsonError(res, 404, "No voucher found for student", { status: "unknown_voucher" });
  }

  return res.json({
    ok: true,
    voucherId: pass.voucher.voucherId,
    studentId: pass.voucher.studentId,
    state: pass.voucher.onChainState,
    issuedAt: pass.voucher.issuedAt,
    redeemedAt: pass.voucher.redeemedAt,
    revokedAt: pass.voucher.revokedAt,
    merchantId: pass.voucher.merchantId ?? null,
  });
});

app.get("/api/student/:voucherId", requireAuth, (req, res) => {
  const state = getState();
  const rawVoucher = state.vouchers[req.params.voucherId];
  if (req.user.role === "student" && rawVoucher && rawVoucher.studentId !== req.user.studentId) {
    return sendJsonError(res, 403, "You may only view your own voucher");
  }
  const voucher = getVoucher(req.params.voucherId);
  if (!voucher) {
    return sendJsonError(res, 404, "unknown_voucher", { status: "unknown_voucher" });
  }
  const student = state.students[voucher.studentId];

  return res.json({
    ok: true,
    voucherId: voucher.voucherId,
    studentId: voucher.studentId,
    studentName: student?.displayName ?? voucher.studentId,
    label: voucher.displayLabel,
    status: getChainState(voucher),
    checkpoint: voucher.redemptionCheckpointId ?? null,
  });
});

app.get("/api/vouchers/:voucherId/history", requireAuth, requireRole("issuer", "auditor"), (req, res) => {
  const state = getState();
  const voucher = state.vouchers[req.params.voucherId];
  if (!voucher) {
    return sendJsonError(res, 404, "Voucher not found");
  }

  return res.json({
    ok: true,
    voucher: getVoucher(req.params.voucherId),
    raw: voucher,
  });
});

app.get(
  /^\/api\/vouchers\/([^/]+)\/history$/,
  requireAuth,
  requireRole("issuer", "auditor"),
  (req, res) => {
  const voucherId = req.params[0];
  const state = getState();
  const voucher = state.vouchers[voucherId];
  if (!voucher) {
    return sendJsonError(res, 404, "Voucher not found");
  }
  return res.json({
    ok: true,
    voucher: getVoucher(voucherId),
    raw: voucher,
  });
  },
);

app.get("/api/audit/history", requireAuth, requireRole("issuer", "auditor"), (_req, res) => {
  res.json({
    ok: true,
    events: getAuditHistory().map(serializeAuditEvent).reverse(),
  });
});

app.get("/api/students/:studentId/pass", requireAuth, (req, res) => {
  if (req.user.role === "student" && req.params.studentId !== req.user.studentId && req.params.studentId !== "me") {
    return sendJsonError(res, 403, "You may only view your own pass");
  }
  const lookupId = req.params.studentId === "me" ? req.user.studentId : req.params.studentId;
  const pass = getStudentPass(lookupId);
  if (!pass) {
    return sendJsonError(res, 404, "Student pass not found");
  }
  return res.json({ ok: true, pass });
});

app.get("/api/students/:studentId/pass.svg", requireAuth, async (req, res) => {
  if (req.user.role === "student" && req.params.studentId !== req.user.studentId && req.params.studentId !== "me") {
    return sendJsonError(res, 403, "You may only view your own pass");
  }
  const lookupId = req.params.studentId === "me" ? req.user.studentId : req.params.studentId;
  const pass = getStudentPass(lookupId);
  if (!pass) {
    return sendJsonError(res, 404, "Student pass not found");
  }
  return sendPassSvg(res, pass.qrPayload);
});

app.get("/api/vouchers/:voucherId/pass", requireAuth, (req, res) => {
  const state = getState();
  const voucher = getVoucher(req.params.voucherId);
  if (!voucher) {
    return sendJsonError(res, 404, "Voucher not found");
  }
  const payload = Buffer.from(
    JSON.stringify({
      voucherId: voucher.voucherId,
      studentId: voucher.studentId,
      programId: voucher.programId,
      displayLabel: voucher.displayLabel,
      issuedAt: voucher.issuedAt,
    }),
  ).toString("base64url");
  const student = state.students[voucher.studentId];
  return res.json({
    ok: true,
    pass: {
      student: student ? { ...student } : null,
      voucher,
      qrPayload: payload,
    },
  });
});

app.get("/api/vouchers/:voucherId/pass.svg", requireAuth, async (req, res) => {
  const voucher = getVoucher(req.params.voucherId);
  if (!voucher) {
    return sendJsonError(res, 404, "Voucher not found");
  }
  const payload = Buffer.from(
    JSON.stringify({
      voucherId: voucher.voucherId,
      studentId: voucher.studentId,
      programId: voucher.programId,
      displayLabel: voucher.displayLabel,
      issuedAt: voucher.issuedAt,
    }),
  ).toString("base64url");
  return sendPassSvg(res, payload);
});

app.get("/api/auditor/history", requireAuth, requireRole("auditor"), (_req, res) => {
  res.json({
    ok: true,
    events: getAuditHistory().map(serializeAuditEvent).reverse(),
  });
});

app.get("/api/solana/status", requireAuth, (_req, res) => {
  res.json(getLedgerStatus());
});

app.get("/api/context", (_req, res) => {
  res.json({
    ok: true,
    deploymentContext: "one university hardship meal voucher program",
    states: ["active", "revoked", "redeemed"],
    chainScope: ["revocation_state", "redemption_state", "audit_checkpoints", "override_logging"],
  });
});

app.use((req, res, next) => {
  if (req.path.startsWith("/api/")) {
    return sendJsonError(res, 404, "Not found");
  }
  return next();
});

app.get("*", (_req, res) => {
  res.sendFile(path.join(__dirname, "..", "public", "index.html"));
});

app.listen(port, () => {
  console.log(`Demo running at http://127.0.0.1:${port}`);
});
