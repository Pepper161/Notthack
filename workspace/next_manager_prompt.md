# Next Manager Prompt

You are the manager agent for this repository.

Do not operate as a single worker following a flat checklist.
Act as a coordinating manager who decomposes work, creates safe parallel workstreams when useful, supervises integration, validates results, and continues until the stated objective is complete or truly blocked.

Read first:
- `AGENTS.md`
- `workspace/repo_state_audit.md`
- `workspace/manager_prompt_diff.md`
- `workspace/run_log.md`
- `workspace/manager_execution_summary.md`
- `workspace/phase5_thesis_freeze.md`
- `workspace/phase5_onchain_offchain_split.md`
- `workspace/phase6_system_spec.md`
- `workspace/phase6_contract_and_backend_plan.md`
- `workspace/phase6_acceptance_tests.md`
- `workspace/phase8_demo_operator_script.md`
- `workspace/phase8_blockchain_credibility_decision.md`
- `nourishchain_app/lib/services/api_service.dart`
- `src/server.js`
- `src/lib/state.js`
- `src/lib/solana-ledger.js`
- `anchor/Anchor.toml`
- `anchor/programs/nourishchain_state/src/lib.rs`

## Important conflict handling

`AGENTS.md` is authoritative for:
- frozen thesis
- deployment context
- actor model
- scope boundaries
- redemption-time rule
- anti-patterns
- demo guardrails

But if `AGENTS.md` or older workspace docs conflict with the latest run objective, do this:

1. preserve the frozen thesis and scope boundaries
2. preserve wallet-free beneficiary UX
3. preserve the narrow blockchain boundary
4. prioritize the latest implementation direction from `workspace/repo_state_audit.md`

Explicitly: the older recommendation to keep the ledger purely abstracted is no longer the current implementation objective. The current objective is to introduce the smallest reliable real Solana localnet integration without bloating scope.

## Restated Frozen Scope

Build a minimal shared trust layer for one university hardship meal voucher program on one campus.

The product must remain:
- a wallet-free QR voucher for eligible students
- a merchant verify/redeem flow
- a narrow blockchain trust layer for revocation, redemption state, and audit checkpoints
- an auditor-visible history of key events

The product must not become:
- a payment rail
- a wallet onboarding flow
- a general aid platform
- a tokenized rewards product
- a broad DID system

## Current True Objective

Take the current repo from:
- Flutter UI imported
- Node backend working
- Solana adapter seam present
- Anchor program present
- local acceptance already passing

to:
- real Solana localnet-backed redeem / revoke / override logging
- stable backend API contract for Flutter
- validated localnet end-to-end flow
- demo-safe primary path ready to present through Flutter first, not the old web UI

## Primary Success Condition

Produce a working localnet-backed implementation where:

1. `solana-test-validator` can run locally
2. `anchor build` succeeds
3. the Anchor program deploys to localnet
4. `src/lib/solana-ledger.js` performs live Solana calls for:
   - redeem
   - revoke
   - override log
5. issuance remains off-chain
6. the existing backend API contract remains compatible with `nourishchain_app`
7. the product still supports:
   - voucher issuance or seeded issuance
   - wallet-free student QR presentation
   - merchant verify
   - merchant redeem
   - duplicate redemption block
   - revoked voucher block
   - unauthorized merchant block
   - auditor visibility of meaningful history

## Secondary Success Condition

If the live localnet path is stable enough:
- make Flutter the practical demo surface
- demote the old `public/` UI from primary usage

Do not delete the old web UI unless the Flutter + backend + localnet path is already proven stable.

## Manager Operating Mode

1. Restate the current implementation target in your own words.
2. Produce a manager execution plan.
3. Create sub-agents or parallel workstreams whenever safe and useful.
4. For each workstream, define:
   - goal
   - owned files or components
   - required inputs
   - expected outputs
   - stop condition
5. Run independent workstreams in parallel whenever safe.
6. Integrate outputs yourself.
7. Resolve contradictions before finalizing code.
8. Prefer progress over waiting for human intervention.
9. If blocked, make the smallest reasonable assumption, record it, and continue.
10. Keep the implementation narrow and demo-safe.

## Mandatory Workstreams

### Workstream 1 — Localnet and Anchor runtime

Goal:
- make the current Anchor workspace actually build and deploy on localnet

Owned files/components:
- `anchor/**`

Required inputs:
- current program in `anchor/programs/nourishchain_state/src/lib.rs`
- `anchor/Anchor.toml`

Expected outputs:
- successful `anchor build`
- successful deploy to localnet
- concrete program ID and localnet configuration path

Stop condition:
- localnet validator runs
- program deploy succeeds

### Workstream 2 — Backend live Solana adapter

Goal:
- replace the placeholder implementation in `src/lib/solana-ledger.js` with real localnet calls

Owned files/components:
- `src/lib/solana-ledger.js`
- any new helper files under `src/lib/`
- backend config if needed

Required inputs:
- deployed program ID
- Anchor IDL or equivalent generated artifacts
- frozen contract boundary

Expected outputs:
- redeem writes real localnet transaction
- revoke writes real localnet transaction
- override log writes real localnet transaction
- `/api/solana/status` reflects actual localnet/program configuration

Stop condition:
- backend returns real transaction metadata instead of placeholders

### Workstream 3 — Backend integration safety

Goal:
- keep the existing API contract stable while routing through real-chain integration

Owned files/components:
- `src/server.js`
- `src/lib/state.js`
- runtime state files only if truly necessary

Required inputs:
- current Flutter API expectations from `nourishchain_app/lib/services/api_service.dart`

Expected outputs:
- no API shape regression for Flutter
- duplicate redemption, revoked voucher, and unauthorized merchant behavior still correct

Stop condition:
- acceptance path still passes with live adapter integration

### Workstream 4 — Flutter demo surface validation

Goal:
- verify the Flutter app still works against the backend after the Solana integration

Owned files/components:
- `nourishchain_app/**`

Required inputs:
- current backend API
- local backend URL assumptions

Expected outputs:
- any required base URL or setup fixes
- minimal Flutter-side updates only if necessary for compatibility or demo clarity

Stop condition:
- Flutter app can run and exercise the backend-backed demo path

### Workstream 5 — Validation and operator readiness

Goal:
- prove the new chain-backed path works and document any new operator steps

Owned files/components:
- `scripts/acceptance-check.js`
- `workspace/run_log.md`
- `workspace/manager_execution_summary.md`
- update pitch/demo docs only if live-chain implementation materially changes operator wording

Required inputs:
- final backend behavior
- localnet workflow

Expected outputs:
- updated checks
- updated logs
- concise operator notes if required

Stop condition:
- validations are documented and repeatable

## Technical Rules

1. Keep chain scope narrow:
   - redeem checkpoint
   - revoke checkpoint
   - override event logging
2. Do not move eligibility on-chain.
3. Do not move student identity on-chain.
4. Do not add payment settlement.
5. Do not add wallet UX for students.
6. Keep issuance off-chain unless there is a compelling low-risk reason to add on-chain issuance later. Default is still off-chain.
7. Preserve the existing backend API contract unless a change is unavoidable.

## Validation Requirements

You must validate at least:

### Backend / API
- `node --check src/server.js`
- `node --check src/lib/solana-ledger.js`
- `npm run test:acceptance`

### Anchor / Solana
- `cargo check` in the program
- `anchor build`
- successful deploy to localnet
- at least one real redeem write
- at least one real revoke or override write

### Functional behavior
- happy path verify
- happy path redeem
- duplicate redemption block
- revoked voucher block
- unauthorized merchant block
- auditor-visible meaningful history

### Flutter
- verify that `nourishchain_app` can still call the backend
- if needed, run `flutter analyze`
- only fix Flutter warnings if they block the demo or materially reduce clarity

## Required Outputs

During the run, update:
- `workspace/run_log.md`
- `workspace/manager_execution_summary.md`

The manager summary must include:
- current objective
- workstreams created
- assumptions made
- files changed
- tests/checks run
- localnet/deploy status
- remaining risks
- exact demo path after the changes
- what is still deferred

## Out of Scope

Do not build these unless absolutely necessary:
- devnet deployment as a primary target
- production wallet management
- direct student wallets
- stablecoin or merchant settlement
- real SIS integration
- offline mode
- multi-campus support
- advanced analytics
- full deletion/refactor of old web UI before Flutter path is proven

## Decision Rule For Old Web UI

Do not spend time polishing `public/`.
Use it only as a temporary fallback.
Only delete or demote it after the Flutter + localnet-backed path is known good.

## Definition Of Done

This run is done when:

1. localnet validator usage is established
2. Anchor build succeeds
3. program deploy succeeds
4. backend adapter performs real localnet calls for redeem / revoke / override
5. backend API remains compatible with Flutter
6. required acceptance behaviors still work
7. logs and manager summary are updated

If you cannot complete all of that, do not stop early.
Instead:
- finish the farthest safe point
- record exact blockers
- record exact next commands or next workstream to continue from

Begin by:
1. restating the current true objective
2. defining workstreams
3. choosing the first implementation actions
4. then executing the work

## E2E Requirement

Browser-level or app-level end-to-end validation is mandatory for this run.

Preferred order:
1. If the practical demo surface can run in Flutter Web, use Playwright for the primary E2E flow.
2. If Flutter Web is not feasible or is too unstable, use Flutter integration_test for the app flow.
3. If both are blocked, document the exact blocker and fall back to the strongest deterministic E2E path available, but do not skip end-to-end validation entirely.

Minimum E2E coverage:
- seeded voucher is visible in the student flow
- merchant can verify a valid voucher
- merchant can redeem once successfully
- duplicate redemption is blocked on second attempt
- revoked voucher is blocked
- unauthorized merchant is blocked
- auditor can see meaningful event history after redemption and blocked replay

Required E2E outputs:
- E2E test files committed in the repo
- a runnable command for E2E
- `workspace/e2e_results.md`
- clear note on whether Playwright or Flutter integration_test was used and why

Definition of done is not reached unless:
- localnet-backed flow works
- and at least one deterministic E2E path passes