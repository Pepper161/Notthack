import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { randomUUID } from "node:crypto";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const dataDir = join(__dirname, "..", "data");
const runtimeStatePath = join(dataDir, "runtime-state.json");

const MAIN_STATES = new Set(["active", "revoked", "redeemed"]);

function nowIso() {
  return new Date().toISOString();
}

function clone(value) {
  return JSON.parse(JSON.stringify(value));
}

function defaultSeedState() {
  const seededAt = nowIso();
  const voucherId = "VCH-1001";
  return {
    meta: {
      programId: "meal-support-2026",
      programName: "University Hardship Meal Support",
      seededAt,
      lastUpdatedAt: seededAt,
      nextEventSeq: 1,
    },
    students: {
      "STU-1001": {
        studentId: "STU-1001",
        displayName: "Aisha K.",
        status: "eligible",
      },
      "STU-1002": {
        studentId: "STU-1002",
        displayName: "Ravi M.",
        status: "not_issued",
      },
    },
    merchants: {
      "CAF-A": {
        merchantId: "CAF-A",
        name: "Campus Cafeteria A",
        approved: true,
      },
      "CAF-B": {
        merchantId: "CAF-B",
        name: "Campus Cafeteria B",
        approved: true,
      },
      "CAF-X": {
        merchantId: "CAF-X",
        name: "Unauthorized Stall",
        approved: false,
      },
    },
    vouchers: {
      [voucherId]: {
        voucherId,
        studentId: "STU-1001",
        programId: "meal-support-2026",
        displayLabel: "Meal Support Voucher",
        amountLabel: "1 meal",
        statusOffchain: "issued",
        issuedAt: seededAt,
        revokedAt: null,
        redeemedAt: null,
        revokedBy: null,
        redeemedBy: null,
        redemptionCheckpointId: null,
        manualOverrideEvents: [],
        blockedRedemptions: [],
        auditTrail: [
          {
            eventId: "evt-seed-issued",
            type: "voucher_issued",
            at: seededAt,
            actorType: "seed",
            actorId: "system",
            checkpointId: null,
            note: "Seeded demo voucher",
          },
        ],
        onChain: {
          voucherHash: null,
          isRevoked: false,
          isRedeemed: false,
          lastEventType: null,
          lastEventAt: null,
          checkpoints: [],
        },
      },
      "VCH-1002": {
        voucherId: "VCH-1002",
        studentId: "STU-1002",
        programId: "meal-support-2026",
        displayLabel: "Meal Support Voucher",
        amountLabel: "1 meal",
        statusOffchain: "issued",
        issuedAt: seededAt,
        revokedAt: null,
        redeemedAt: null,
        revokedBy: null,
        redeemedBy: null,
        redemptionCheckpointId: null,
        manualOverrideEvents: [],
        blockedRedemptions: [],
        auditTrail: [
          {
            eventId: "evt-seed-issued-2",
            type: "voucher_issued",
            at: seededAt,
            actorType: "seed",
            actorId: "system",
            checkpointId: null,
            note: "Seeded demo voucher",
          },
        ],
        onChain: {
          voucherHash: null,
          isRevoked: false,
          isRedeemed: false,
          lastEventType: null,
          lastEventAt: null,
          checkpoints: [],
        },
      },
    },
    auditEvents: [],
  };
}

function ensureDataDir() {
  if (!existsSync(dataDir)) {
    throw new Error(`Missing data directory: ${dataDir}`);
  }
}

function writeRuntimeState(state) {
  ensureDataDir();
  state.meta.lastUpdatedAt = nowIso();
  writeFileSync(runtimeStatePath, JSON.stringify(state, null, 2), "utf8");
}

function readRuntimeState() {
  ensureDataDir();
  if (!existsSync(runtimeStatePath)) {
    const initial = defaultSeedState();
    writeRuntimeState(initial);
    return initial;
  }
  const raw = readFileSync(runtimeStatePath, "utf8");
  return JSON.parse(raw);
}

function withState(mutator) {
  const state = readRuntimeState();
  const result = mutator(state);
  writeRuntimeState(state);
  return result;
}

function getState() {
  return clone(readRuntimeState());
}

function resetState() {
  const state = defaultSeedState();
  writeRuntimeState(state);
  return clone(state);
}

function nextId(state, prefix) {
  const seq = state.meta.nextEventSeq;
  state.meta.nextEventSeq += 1;
  return `${prefix}-${String(seq).padStart(4, "0")}`;
}

function ensureVoucher(state, voucherId) {
  const voucher = state.vouchers[voucherId];
  if (!voucher) {
    return null;
  }
  if (!voucher.onChain) {
    voucher.onChain = {
      voucherHash: null,
      isRevoked: false,
      isRedeemed: false,
      lastEventType: null,
      lastEventAt: null,
      checkpoints: [],
    };
  }
  return voucher;
}

function deriveVoucherHash(voucher) {
  const payload = {
    voucherId: voucher.voucherId,
    studentId: voucher.studentId,
    programId: voucher.programId,
  };
  return Buffer.from(JSON.stringify(payload)).toString("base64url");
}

function summarizeVoucher(voucher) {
  const onChain = voucher.onChain ?? {};
  const chainState = onChain.isRedeemed
    ? "redeemed"
    : onChain.isRevoked
      ? "revoked"
      : "active";

  return {
    voucherId: voucher.voucherId,
    studentId: voucher.studentId,
    programId: voucher.programId,
    displayLabel: voucher.displayLabel,
    amountLabel: voucher.amountLabel,
    statusOffchain: voucher.statusOffchain,
    onChainState: chainState,
    isRevoked: Boolean(onChain.isRevoked),
    isRedeemed: Boolean(onChain.isRedeemed),
    merchantId: voucher.redeemedBy ?? null,
    lastEventType: onChain.lastEventType,
    lastEventAt: onChain.lastEventAt,
    redemptionCheckpointId: voucher.redemptionCheckpointId,
    issuedAt: voucher.issuedAt,
    revokedAt: voucher.revokedAt,
    redeemedAt: voucher.redeemedAt,
    manualOverrideCount: voucher.manualOverrideEvents.length,
    blockedRedemptionCount: voucher.blockedRedemptions.length,
  };
}

function recordAuditEvent(state, voucher, event) {
  const eventId = nextId(state, "evt");
  const record = {
    eventId,
    voucherId: voucher.voucherId,
    type: event.type,
    at: event.at ?? nowIso(),
    actorType: event.actorType ?? "system",
    actorId: event.actorId ?? "system",
    reason: event.reason ?? null,
    note: event.note ?? null,
    checkpointId: event.checkpointId ?? null,
    relatedCheckpointId: event.relatedCheckpointId ?? null,
    relatedOnChainEventId: event.relatedOnChainEventId ?? null,
    overrideEventHash: event.overrideEventHash ?? null,
    details: event.details ?? null,
  };
  voucher.auditTrail.push(record);
  state.auditEvents.push(record);
  return record;
}

function recordBlockedRedemption(state, voucher, event) {
  const eventId = nextId(state, "blk");
  const record = {
    eventId,
    voucherId: voucher ? voucher.voucherId : event.voucherId,
    type: "voucher_redemption_blocked",
    at: event.at ?? nowIso(),
    actorType: event.actorType ?? "merchant",
    actorId: event.actorId ?? "system",
    blockedReason: event.blockedReason ?? "blocked",
    reason: event.reason ?? null,
    checkpointId: event.checkpointId ?? null,
    relatedCheckpointId: event.relatedCheckpointId ?? null,
    details: event.details ?? null,
  };
  if (voucher) {
    voucher.blockedRedemptions.push(record);
  }
  state.auditEvents.push(record);
  return record;
}

function appendCheckpoint(state, voucher, type, actorId, actorType, details = {}) {
  const eventId = nextId(state, "chk");
  const at = nowIso();
  const checkpoint = {
    checkpointId: eventId,
    type,
    at,
    actorType,
    actorId,
    voucherId: voucher.voucherId,
    details,
  };
  voucher.onChain.checkpoints.push(checkpoint);
  voucher.onChain.lastEventType = type;
  voucher.onChain.lastEventAt = at;
  return checkpoint;
}

function getMerchantApproval(state, merchantId) {
  return state.merchants[merchantId] ?? null;
}

function issueVoucher({ voucherId, studentId, actorId = "staff", note = "Issued by Student Affairs" }) {
  return withState((state) => {
    const student = state.students[studentId];
    if (!student) {
      throw new Error(`Unknown student: ${studentId}`);
    }

    const id = voucherId ?? `VCH-${String(Object.keys(state.vouchers).length + 1001)}`;
    if (state.vouchers[id]) {
      throw new Error(`Voucher already exists: ${id}`);
    }

    const at = nowIso();
    const voucher = {
      voucherId: id,
      studentId,
      programId: state.meta.programId,
      displayLabel: "Meal Support Voucher",
      amountLabel: "1 meal",
      statusOffchain: "issued",
      issuedAt: at,
      revokedAt: null,
      redeemedAt: null,
      revokedBy: null,
      redeemedBy: null,
      redemptionCheckpointId: null,
      manualOverrideEvents: [],
      blockedRedemptions: [],
      auditTrail: [],
      onChain: {
        voucherHash: deriveVoucherHash({ voucherId: id, studentId, programId: state.meta.programId }),
        isRevoked: false,
        isRedeemed: false,
        lastEventType: null,
        lastEventAt: null,
        checkpoints: [],
      },
    };

    state.vouchers[id] = voucher;
    student.status = "eligible";
    recordAuditEvent(state, voucher, {
      type: "voucher_issued",
      at,
      actorType: "issuer",
      actorId,
      note,
      details: { studentId },
    });
    return summarizeVoucher(voucher);
  });
}

function revokeVoucher({ voucherId, actorId = "staff", reason = "Eligibility revoked by Student Affairs" }) {
  return withState((state) => {
    const voucher = ensureVoucher(state, voucherId);
    if (!voucher) {
      throw new Error(`Unknown voucher: ${voucherId}`);
    }

    const at = nowIso();
    voucher.statusOffchain = "revoked";
    voucher.revokedAt = at;
    voucher.revokedBy = actorId;
    voucher.onChain.isRevoked = true;

    const checkpoint = appendCheckpoint(state, voucher, "voucher_revoked", actorId, "issuer", { reason });
    recordAuditEvent(state, voucher, {
      type: "voucher_revoked",
      at,
      actorType: "issuer",
      actorId,
      reason,
      checkpointId: checkpoint.checkpointId,
    });
    return summarizeVoucher(voucher);
  });
}

function logOverride({ voucherId, actorId = "staff", reason = "Manual override approved" }) {
  return withState((state) => {
    const voucher = ensureVoucher(state, voucherId);
    if (!voucher) {
      throw new Error(`Unknown voucher: ${voucherId}`);
    }

    const at = nowIso();
    const overrideEventHash = Buffer.from(
      JSON.stringify({
        voucherId,
        actorId,
        reason,
        at,
      }),
    ).toString("base64url");

    const checkpoint = appendCheckpoint(state, voucher, "override_logged", actorId, "issuer", {
      reason,
      overrideEventHash,
    });
    voucher.manualOverrideEvents.push({
      at,
      actorId,
      reason,
      overrideEventHash,
      checkpointId: checkpoint.checkpointId,
    });

    recordAuditEvent(state, voucher, {
      type: "override_logged",
      at,
      actorType: "issuer",
      actorId,
      reason,
      checkpointId: checkpoint.checkpointId,
      overrideEventHash,
      details: { reason },
    });

    return {
      voucher: summarizeVoucher(voucher),
      overrideEventHash,
      checkpointId: checkpoint.checkpointId,
    };
  });
}

function verifyVoucher({ merchantId, voucherId }) {
  const state = getState();
  const merchant = getMerchantApproval(state, merchantId);
  if (!merchant) {
    return {
      ok: false,
      code: "unknown_merchant",
      reason: "Merchant not found",
    };
  }
  if (!merchant.approved) {
    return {
      ok: false,
      code: "merchant_not_approved",
      reason: "Merchant is not approved",
    };
  }

  const voucher = ensureVoucher(state, voucherId);
  if (!voucher) {
    return {
      ok: false,
      code: "unknown_voucher",
      reason: "Voucher does not exist",
    };
  }

  const onChain = voucher.onChain;
  const onChainState = onChain.isRedeemed
    ? "redeemed"
    : onChain.isRevoked
      ? "revoked"
      : "active";

  if (onChainState === "revoked") {
    return {
      ok: false,
      code: "revoked",
      reason: "Voucher is revoked",
      voucher: summarizeVoucher(voucher),
    };
  }

  if (onChainState === "redeemed") {
    return {
      ok: false,
      code: "already_redeemed",
      reason: "Voucher already redeemed",
      voucher: summarizeVoucher(voucher),
    };
  }

  return {
    ok: true,
    code: "valid",
    reason: "Voucher is valid",
    voucher: summarizeVoucher(voucher),
  };
}

function redeemVoucher({ merchantId, voucherId, actorId = merchantId }) {
  return withState((state) => {
    const merchant = getMerchantApproval(state, merchantId);
    const voucher = ensureVoucher(state, voucherId);
    const latestCheckpointId = voucher?.onChain.checkpoints.at(-1)?.checkpointId ?? null;

    if (!merchant) {
      const blockedEvent = recordBlockedRedemption(state, voucher, {
        voucherId,
        actorType: "merchant",
        actorId,
        blockedReason: "unknown_merchant",
        reason: "Merchant not found",
        relatedCheckpointId: latestCheckpointId,
      });
      return {
        ok: false,
        code: "unknown_merchant",
        reason: "Merchant not found",
        blockedEvent,
      };
    }
    if (!merchant.approved) {
      const blockedEvent = recordBlockedRedemption(state, voucher, {
        voucherId,
        actorType: "merchant",
        actorId,
        blockedReason: "merchant_not_approved",
        reason: "Merchant is not approved",
        relatedCheckpointId: latestCheckpointId,
      });
      return {
        ok: false,
        code: "merchant_not_approved",
        reason: "Merchant is not approved",
        blockedEvent,
      };
    }

    if (!voucher) {
      const blockedEvent = recordBlockedRedemption(state, null, {
        voucherId,
        actorType: "merchant",
        actorId,
        blockedReason: "unknown_voucher",
        reason: "Voucher does not exist",
        relatedCheckpointId: null,
      });
      return {
        ok: false,
        code: "unknown_voucher",
        reason: "Voucher does not exist",
        blockedEvent,
      };
    }

    if (voucher.onChain.isRevoked) {
      const blockedEvent = recordBlockedRedemption(state, voucher, {
        voucherId,
        actorType: "merchant",
        actorId,
        blockedReason: "revoked",
        reason: "Voucher is revoked",
        relatedCheckpointId: latestCheckpointId,
      });
      return {
        ok: false,
        code: "revoked",
        reason: "Voucher is revoked",
        voucher: summarizeVoucher(voucher),
        blockedEvent,
      };
    }

    if (voucher.onChain.isRedeemed) {
      const blockedEvent = recordBlockedRedemption(state, voucher, {
        voucherId,
        actorType: "merchant",
        actorId,
        blockedReason: "already_redeemed",
        reason: "Voucher already redeemed",
        relatedCheckpointId: latestCheckpointId,
      });
      return {
        ok: false,
        code: "already_redeemed",
        reason: "Voucher already redeemed",
        voucher: summarizeVoucher(voucher),
        blockedEvent,
      };
    }

    const at = nowIso();
    voucher.onChain.isRedeemed = true;
    voucher.onChain.isRevoked = Boolean(voucher.onChain.isRevoked);
    voucher.redeemedAt = at;
    voucher.redeemedBy = merchantId;
    const checkpoint = appendCheckpoint(state, voucher, "voucher_redeemed", actorId, "merchant", {
      merchantId,
    });
    voucher.redemptionCheckpointId = checkpoint.checkpointId;
    recordAuditEvent(state, voucher, {
      type: "voucher_redeemed",
      at,
      actorType: "merchant",
      actorId,
      checkpointId: checkpoint.checkpointId,
      relatedOnChainEventId: checkpoint.checkpointId,
    });

    return {
      ok: true,
      code: "redeemed",
      reason: "Voucher redeemed",
      checkpointId: checkpoint.checkpointId,
      voucher: summarizeVoucher(voucher),
    };
  });
}

function createPassToken(voucher) {
  return Buffer.from(
    JSON.stringify({
      voucherId: voucher.voucherId,
      studentId: voucher.studentId,
      programId: voucher.programId,
      displayLabel: voucher.displayLabel,
      issuedAt: voucher.issuedAt,
    }),
  ).toString("base64url");
}

function listVouchers() {
  const state = getState();
  return Object.values(state.vouchers).map(summarizeVoucher);
}

function getVoucher(voucherId) {
  const state = getState();
  const voucher = state.vouchers[voucherId];
  return voucher ? summarizeVoucher(voucher) : null;
}

function getVoucherDetail(voucherId) {
  const state = getState();
  const voucher = state.vouchers[voucherId];
  return voucher ? clone(voucher) : null;
}

function listMerchants() {
  const state = getState();
  return Object.values(state.merchants).map((merchant) => ({ ...merchant }));
}

function listStudents() {
  const state = getState();
  return Object.values(state.students).map((student) => ({ ...student }));
}

function getProgramSummary() {
  const state = getState();
  return {
    ...state.meta,
    voucherCount: Object.keys(state.vouchers).length,
    merchantCount: Object.keys(state.merchants).length,
    studentCount: Object.keys(state.students).length,
  };
}

function getAuditHistory() {
  const state = getState();
  return clone(state.auditEvents);
}

function getVoucherHistory(voucherId) {
  const state = getState();
  const voucher = state.vouchers[voucherId];
  if (!voucher) {
    return null;
  }
  return {
    voucher: summarizeVoucher(voucher),
    raw: clone(voucher),
  };
}

function getStudentPass(studentId) {
  const state = getState();
  const voucher = Object.values(state.vouchers).find((entry) => entry.studentId === studentId);
  if (!voucher) {
    return null;
  }

  return {
    student: state.students[studentId] ? { ...state.students[studentId] } : null,
    voucher: summarizeVoucher(voucher),
    qrPayload: createPassToken(voucher),
  };
}

function applyDemoReset() {
  return resetState();
}

export {
  MAIN_STATES,
  applyDemoReset,
  deriveVoucherHash,
  getAuditHistory,
  getProgramSummary,
  getState,
  getStudentPass,
  listStudents,
  getVoucher,
  getVoucherDetail,
  getVoucherHistory,
  listMerchants,
  listVouchers,
  logOverride,
  issueVoucher,
  redeemVoucher,
  revokeVoucher,
  summarizeVoucher,
  verifyVoucher,
  writeRuntimeState,
};
