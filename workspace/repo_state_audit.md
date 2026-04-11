# Repo State Audit

## Current Confirmed Product State

- The frozen thesis is still valid:
  - one-campus university hardship meal voucher program
  - wallet-free student QR flow
  - blockchain only for redemption state, revocation state, audit checkpoints, and override logging
- The required demo path already exists in product terms:
  - seeded or issued voucher
  - student QR presentation
  - merchant verify
  - merchant redeem
  - duplicate redemption block
  - revoked voucher block
  - unauthorized merchant block
  - auditor history
- The project is no longer in concept-selection mode.
- The product is no longer missing UI.
- The main implementation gap is not the user flow; it is replacing the demo-safe ledger seam with a live Solana-backed path.

## Current Confirmed Technical State

### Backend

- The Node backend in `src/` is still the live API surface used by the product.
- Current entrypoint remains `src/server.js`.
- Existing API contract is already consumed by the Flutter app and must be preserved unless there is a very strong reason to version it.
- Local acceptance checks still pass against the Node backend.
- `src/lib/solana-ledger.js` now exists as an adapter seam.
- That adapter is still a stub:
  - it returns placeholder checkpoint objects
  - it does not yet send real Solana transactions

### Chain / Contract

- A minimal Anchor workspace now exists under `anchor/`.
- The current contract direction is narrow and aligned with scope:
  - one program: `nourishchain_state`
  - one PDA per voucher hash
  - three instructions:
    - `record_redeem`
    - `record_revoke`
    - `log_override`
- Issuance remains intentionally off-chain.
- `cargo check` for the Anchor program passes inside WSL.
- Full `anchor build` has not yet been completed end-to-end because the first SBF bootstrap is slow and was stopped after host-side compilation was confirmed.

### Environment

- Windows side is usable for Flutter and backend work:
  - Flutter OK
  - Android toolchain OK
  - Rust OK
- WSL side is usable for Solana / Anchor:
  - Ubuntu installed
  - Rust installed
  - Node installed
  - `solana-cli 3.1.13`
  - `anchor-cli 0.32.1`

### UI

- The Flutter app from `Charles_branch` is now present in `nourishchain_app/`.
- Flutter app currently targets the Node backend at `http://localhost:3000/api`.
- The Flutter app is the intended forward UI.
- The old web UI in `public/` still exists and is still what `npm start` serves.
- Therefore:
  - the old web UI is not yet deleted
  - the Flutter app is not yet the default served experience

## Current Confirmed Demo / Pitch State

- Judge-facing strategy docs exist through Phase 9.
- Demo script exists and is coherent.
- Pitch script, slide outline, and Q&A bank already exist.
- The current strategic risk is no longer “we need a pitch.”
- The current strategic risk is “the implementation story may drift from the live-chain direction the team now wants.”

## Stale Assumptions From Older Prompts

### 1. “The main job is to build the MVP from scratch”

This is stale.

Why:
- core MVP already exists
- acceptance checks already pass
- Flutter UI already exists
- judge package already exists

### 2. “Keep the local ledger abstraction and do not add a real-chain checkpoint”

This is stale as an execution objective.

Why:
- `workspace/phase8_blockchain_credibility_decision.md` chose demo safety over real-chain work for the earlier hackathon package
- since then, the user explicitly changed direction and asked to introduce a real Solana chain
- the next manager run must treat real localnet integration as the active objective

How to resolve:
- preserve the frozen thesis and scope
- override the older “do not add real-chain checkpoint” recommendation for implementation purposes
- keep the same narrow chain boundary

### 3. “The old web UI is the main surface”

This is stale.

Why:
- `nourishchain_app/` now exists and is the intended UI direction
- the old `public/` UI is temporary compatibility scaffolding

### 4. “Delete `src/` because old JS can be discarded”

This is stale.

Why:
- `src/` is no longer just throwaway UI code
- `src/` now contains the live backend and the Solana adapter seam
- deleting it now would break the current app

### 5. “The next important work is more pitch / demo planning”

This is stale.

Why:
- pitch materials already exist
- the new bottleneck is technical integration: localnet, deploy, adapter, and Flutter-backed demo path

## Unresolved Risks

1. `anchor build` and `anchor deploy` on localnet have not yet been completed.
2. The backend does not yet submit real Solana transactions.
3. No IDL or generated client path is wired into the Node backend yet.
4. `GET /api/solana/status` still reports stub status rather than live program connectivity.
5. The Flutter app still depends on localhost assumptions and may need small setup fixes per target platform.
6. The old `public/` UI still exists, which can create confusion about what the true demo surface is.
7. `src/data/runtime-state.json` is still part of the live state path and may need to remain partially authoritative until on-chain writes are proven stable.
8. Acceptance coverage currently proves backend behavior, but not yet real-chain side effects.

## Exact Recommended Objective For The Next Run

Implement the smallest reliable real-Solana integration on localnet while preserving the frozen thesis, API contract, and wallet-free UX.

More concretely:

1. make `anchor build` complete successfully
2. run `solana-test-validator`
3. deploy `nourishchain_state` to localnet
4. wire `src/lib/solana-ledger.js` to make live Anchor calls for:
   - redeem
   - revoke
   - override log
5. keep issuance off-chain
6. keep the existing backend API contract stable for `nourishchain_app`
7. verify that:
   - redeem writes real localnet transactions
   - duplicate redemption remains blocked
   - revoked voucher remains blocked
   - unauthorized merchant remains blocked
   - auditor history still works
8. if stable, shift the primary demo path toward Flutter and demote the old `public/` UI

## Practical Reading Of AGENTS.md vs Latest State

`AGENTS.md` is still correct on thesis, scope, actor model, redemption-time rule, anti-patterns, and chain boundary.

What it does not reflect cleanly anymore:

- it still reads like a broad implementation operating system from earlier phases
- it does not capture that the repo now has:
  - a Flutter app
  - an Anchor workspace
  - a Solana adapter seam
  - an already-complete judge package

So the next manager prompt should:

- keep AGENTS thesis and guardrails
- ignore stale planning emphasis
- focus execution on real localnet integration and demo-surface consolidation
