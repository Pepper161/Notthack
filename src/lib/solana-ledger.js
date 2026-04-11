import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { createHash } from "node:crypto";
import { fileURLToPath } from "node:url";
import * as anchor from "@coral-xyz/anchor";
import { Connection, Keypair, PublicKey, SystemProgram } from "@solana/web3.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, "..", "..");
const anchorRoot = path.join(repoRoot, "anchor");

const DEFAULT_CLUSTER = process.env.SOLANA_CLUSTER ?? "localnet";
const DEFAULT_RPC_URL = process.env.SOLANA_RPC_URL ?? "http://127.0.0.1:8899";
const DEFAULT_PROGRAM_KEYPAIR_PATH =
  process.env.SOLANA_PROGRAM_KEYPAIR_PATH ??
  path.join(anchorRoot, "target", "deploy", "mealtrust_state-keypair.json");
const DEFAULT_AUTHORITY_KEYPAIR_PATH =
  process.env.SOLANA_AUTHORITY_KEYPAIR_PATH ??
  path.join(os.homedir(), ".config", "solana", "id.json");
const DEFAULT_IDL_PATH =
  process.env.SOLANA_IDL_PATH ?? path.join(anchorRoot, "target", "idl", "mealtrust_state.json");

const STATIC_IDL = {
  version: "0.1.0",
  name: "mealtrust_state",
  address: "AWyYvJCuYwn2FQvQj4P3nz3vmTgn8HgJBY6itReuy1pu",
  instructions: [
    {
      name: "recordRedeem",
      accounts: [
        { name: "voucherRecord", isMut: true, isSigner: false },
        { name: "authority", isMut: true, isSigner: true },
        { name: "systemProgram", isMut: false, isSigner: false },
      ],
      args: [
        { name: "voucherHash", type: { array: ["u8", 32] } },
        { name: "checkpointRef", type: { array: ["u8", 32] } },
      ],
    },
    {
      name: "recordRevoke",
      accounts: [
        { name: "voucherRecord", isMut: true, isSigner: false },
        { name: "authority", isMut: true, isSigner: true },
        { name: "systemProgram", isMut: false, isSigner: false },
      ],
      args: [
        { name: "voucherHash", type: { array: ["u8", 32] } },
        { name: "checkpointRef", type: { array: ["u8", 32] } },
      ],
    },
    {
      name: "logOverride",
      accounts: [
        { name: "voucherRecord", isMut: true, isSigner: false },
        { name: "authority", isMut: true, isSigner: true },
        { name: "systemProgram", isMut: false, isSigner: false },
      ],
      args: [
        { name: "voucherHash", type: { array: ["u8", 32] } },
        { name: "overrideRef", type: { array: ["u8", 32] } },
      ],
    },
  ],
  accounts: [
    {
      name: "voucherRecord",
      type: {
        kind: "struct",
        fields: [
          { name: "voucherHash", type: { array: ["u8", 32] } },
          { name: "state", type: "u8" },
          { name: "bump", type: "u8" },
          { name: "lastActionAt", type: "i64" },
          { name: "lastActionRef", type: { array: ["u8", 32] } },
          { name: "redeemCount", type: "u32" },
          { name: "revokeCount", type: "u32" },
          { name: "overrideCount", type: "u32" },
        ],
      },
    },
  ],
  events: [
    {
      name: "RedeemRecorded",
      fields: [
        { name: "voucherHash", type: { array: ["u8", 32] }, index: false },
        { name: "checkpointRef", type: { array: ["u8", 32] }, index: false },
        { name: "authority", type: "publicKey", index: false },
        { name: "recordedAt", type: "i64", index: false },
      ],
    },
    {
      name: "RevokeRecorded",
      fields: [
        { name: "voucherHash", type: { array: ["u8", 32] }, index: false },
        { name: "checkpointRef", type: { array: ["u8", 32] }, index: false },
        { name: "authority", type: "publicKey", index: false },
        { name: "recordedAt", type: "i64", index: false },
      ],
    },
    {
      name: "OverrideLogged",
      fields: [
        { name: "voucherHash", type: { array: ["u8", 32] }, index: false },
        { name: "overrideRef", type: { array: ["u8", 32] }, index: false },
        { name: "authority", type: "publicKey", index: false },
        { name: "recordedAt", type: "i64", index: false },
      ],
    },
  ],
};

function toCheckpointDigest(parts) {
  const hash = createHash("sha256");
  for (const part of parts) {
    hash.update(String(part ?? ""));
    hash.update("|");
  }
  return hash.digest();
}

function toBase58Keypair(keypair) {
  return keypair?.publicKey?.toBase58?.() ?? null;
}

function readJsonIfExists(filePath) {
  if (!filePath || !fs.existsSync(filePath)) return null;
  return JSON.parse(fs.readFileSync(filePath, "utf8"));
}

function readKeypair(filePath) {
  const raw = readJsonIfExists(filePath);
  if (!raw) return null;
  return Keypair.fromSecretKey(Uint8Array.from(raw));
}

function loadIdl(programId) {
  const idl = readJsonIfExists(DEFAULT_IDL_PATH);
  const resolved = idl ?? STATIC_IDL;
  if (programId && !resolved.address) {
    return { ...resolved, address: programId.toBase58() };
  }
  return resolved;
}

function loadProgramId() {
  if (process.env.SOLANA_PROGRAM_ID) {
    return new PublicKey(process.env.SOLANA_PROGRAM_ID);
  }

  const keypair = readKeypair(DEFAULT_PROGRAM_KEYPAIR_PATH);
  return keypair ? keypair.publicKey : null;
}

function loadAuthorityKeypair() {
  return readKeypair(DEFAULT_AUTHORITY_KEYPAIR_PATH);
}

function getLedgerConfig() {
  const programId = loadProgramId();
  const authority = loadAuthorityKeypair();

  return {
    cluster: DEFAULT_CLUSTER,
    rpcUrl: DEFAULT_RPC_URL,
    programId: programId?.toBase58() ?? null,
    authorityPubkey: toBase58Keypair(authority),
    authorityKeypair: authority,
    enabled: Boolean(programId && authority),
  };
}

function getLedgerStatus() {
  const config = getLedgerConfig();
  return {
    enabled: config.enabled,
    configured: config.enabled,
    mode: config.enabled ? "localnet_live" : "local_demo",
    cluster: config.cluster,
    rpcUrl: config.rpcUrl,
    programId: config.programId,
    authorityPubkey: config.authorityPubkey,
    wallet: config.authorityPubkey,
    balance: null,
  };
}

function toExplorerUrl(signature, rpcUrl, cluster) {
  if (!signature) return null;
  if (!rpcUrl) return null;
  const encodedRpc = encodeURIComponent(rpcUrl);
  const clusterTag = cluster === "localnet" ? "custom" : cluster;
  return `https://explorer.solana.com/tx/${signature}?cluster=${clusterTag}&customUrl=${encodedRpc}`;
}

function hash32FromParts(parts) {
  return toCheckpointDigest(parts);
}

function buildFallbackRecord(action, payload) {
  const status = getLedgerStatus();
  const checkpointRef =
    payload.checkpointRef ??
    toCheckpointDigest([action, payload.voucherId, payload.actorId, payload.reference ?? ""]).toString(
      "hex",
    );

  return {
    recorded: false,
    action,
    checkpointRef,
    signature: null,
    explorerUrl: null,
    cluster: status.cluster,
    programId: status.programId,
    authorityPubkey: status.authorityPubkey,
    mode: status.mode,
    error: null,
  };
}

function getProviderAndProgram() {
  const config = getLedgerConfig();
  if (!config.enabled) return null;

  const authority = config.authorityKeypair;
  const connection = new Connection(config.rpcUrl, "confirmed");
  const wallet = new anchor.Wallet(authority);
  const provider = new anchor.AnchorProvider(connection, wallet, {
    commitment: "confirmed",
  });
  const programId = new PublicKey(config.programId);
  const idl = loadIdl(programId);
  const program = new anchor.Program(idl, provider);
  return { config, connection, provider, program };
}

async function sendCheckpoint(action, methodName, payload, refKey) {
  const live = getProviderAndProgram();
  const fallback = buildFallbackRecord(action, payload);
  if (!live) return fallback;

  try {
    const { config, program } = live;
    const programId = new PublicKey(config.programId);
    const voucherHash = hash32FromParts([
      payload.voucherId,
      payload.studentId ?? "",
      payload.programId ?? "",
    ]);
    const checkpointRef = payload.checkpointRef ?? payload.reference ?? payload.voucherId ?? action;
    const checkpointDigest = hash32FromParts([
      action,
      payload.voucherId,
      payload.actorId,
      checkpointRef,
    ]);
    const [voucherRecordPda] = PublicKey.findProgramAddressSync(
      [Buffer.from("voucher"), Buffer.from(voucherHash)],
      programId,
    );

    const rpcArgs = [Array.from(voucherHash), Array.from(checkpointDigest)];
    const instruction = program.methods[methodName](...rpcArgs).accounts({
      voucherRecord: voucherRecordPda,
      authority: program.provider.wallet.publicKey,
      systemProgram: SystemProgram.programId,
    });
    const signature = await instruction.rpc();

    return {
      recorded: true,
      action,
      checkpointRef,
      signature,
      explorerUrl: toExplorerUrl(signature, config.rpcUrl, config.cluster),
      cluster: config.cluster,
      programId: config.programId,
      authorityPubkey: config.authorityPubkey,
      mode: "localnet_live",
      voucherRecordPubkey: voucherRecordPda.toBase58(),
      voucherHash: Buffer.from(voucherHash).toString("hex"),
      checkpointDigest: Buffer.from(checkpointDigest).toString("hex"),
      error: null,
      refKey,
    };
  } catch (error) {
    return {
      ...fallback,
      error: error instanceof Error ? error.message : String(error),
      refKey,
    };
  }
}

async function recordVoucherRedeemed(payload) {
  return sendCheckpoint("voucher_redeemed", "recordRedeem", payload, "checkpointRef");
}

async function recordVoucherRevoked(payload) {
  return sendCheckpoint("voucher_revoked", "recordRevoke", payload, "checkpointRef");
}

async function recordOverrideLogged(payload) {
  return sendCheckpoint("override_logged", "logOverride", payload, "overrideRef");
}

async function describeOffchainIssuance(payload) {
  const status = getLedgerStatus();
  return {
    recorded: false,
    action: "voucher_issued_offchain",
    checkpointRef: payload.voucherId,
    signature: null,
    explorerUrl: null,
    cluster: status.cluster,
    programId: status.programId,
    authorityPubkey: status.authorityPubkey,
    mode: status.mode,
  };
}

export {
  describeOffchainIssuance,
  getLedgerStatus,
  recordOverrideLogged,
  recordVoucherRedeemed,
  recordVoucherRevoked,
};
