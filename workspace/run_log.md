# Run Log

## Scope

Completed Phase 0 to Phase 6 plus the smallest demo-safe implementation and the judge-facing strategy package for the university hardship meal voucher concept.

## Files Read

- `AGENTS.md`
- `docs/BGA_NottsHack_Winning_Workflow.md`
- `docs/BGA_Teack.md`
- `docs/BGA Track 1（NottsHack）要件調査と領域別の課題分析レポート.md`

## Public Research Used

- BGA forum and BGA 2025 awards pages for sponsor and winner signals
- World Bank DPI / ID4D / Findex signals for public-benefit and identity problems
- European Commission ESPR / DPP and GS1 EPCIS for compliance-passport problems
- UNFCCC and Japan MOE MRV sources for climate-audit problems
- FTC scam data for consumer-protection candidate generation
- Rumsan Rahat and Plastiks as deployment-pattern examples

## Key Assumptions

1. The BGA judging image in the local brief is not machine-readable, so weighting was inferred from the written judging language and public award patterns.
2. Publicly named winners were treated as directional signals, not as exact reverse-engineered scoring weights.
3. The workflow's definition of success is better served by a concept with a crisp trust model than by a concept with broader market size but weaker blockchain necessity.

## Phase Results

### Phase 0

- Reverse-engineered BGA preference toward real institutional pain, backend trust layers, and pilotable systems.

### Phase 1

- Generated 20 candidates.
- 15 survived first filtering.

### Phase 2

- Validated top 3:
  - P01 aid credential + redemption audit
  - P04 compliance passport for SME exporters
  - P07 MRV audit trail for small climate projects

### Phase 3

- P01 passed strongest blockchain necessity test.
- P04 and P07 remained credible but weaker.

### Phase 4

- Selected P01 as the recommended concept.

### Phase 5

- Fixed one deployment context: university hardship meal vouchers
- Froze thesis and 3-sentence pitch
- Defined minimum actor model
- Froze on-chain / off-chain boundary
- Designed 90–120 second demo with duplicate-redemption failure
- Wrote a short DB-vs-blockchain rebuttal
- Defined pilot path and non-MVP cuts

### Phase 6

- Froze system boundary and redemption-time logic
- Defined explicit state machine
- Defined minimal contract and backend plan
- Ordered implementation by demo risk
- Created UI task breakdown
- Created believable seed data
- Wrote acceptance tests for happy path and duplicate redemption
- Deferred risky non-essential features explicitly

### Implementation Progress

- implemented a local Express backend with explicit ledger-style state transitions in `src/`
- implemented merchant verify/redeem, issuer issue/revoke/override, student QR pass, and auditor history in `public/`
- kept student flow wallet-free
- enforced the frozen redemption-time rule: no hardship re-evaluation at checkout
- added acceptance checks for happy path, duplicate redemption, revoked voucher, unauthorized merchant, auditor visibility, and override logging

### Phase 7-9 Package

- added harsh judge simulation and win strategy
- added demo polish plan and live operator script
- added UI fix list for judge-facing clarity
- made an explicit blockchain credibility decision to keep the demo-safe ledger abstraction
- added Q&A bank, slide outline, pitch script, and submission checklist

### Phase 7-9 Planning Progress

- judged the current build harshly against BGA criteria
- decided not to add a real-chain checkpoint for the hackathon demo
- drafted demo polish, operator script, blockchain credibility wording, Q&A bank, slide outline, pitch script, and submission checklist

## Final Recommendation

Build around:

`A wallet-free QR hardship meal voucher for university students, using blockchain only for revocation, shared redemption state, audit checkpoints, and override audit events.`

## Blockers

None that blocked implementation.

## Next Best Action

Move to demo rehearsal and pitch alignment with this order:

1. rehearse the 90–120 second happy path plus duplicate-redemption failure
2. capture screenshots or a short demo video
3. tighten the spoken rebuttal for `why not a normal server?`
4. only then consider a real on-chain adapter if it improves judge confidence without risking stability

## Judge Calibration

- The project is competitive if the team keeps the story on the shared-trust layer and executes the demo cleanly.
- The biggest risk is sounding like a generic voucher admin tool.
- The best defense is a crisp, repeated explanation of revocation, redemption state, and audit checkpoints.

## Current Implementation Notes

- the backend uses a local ledger abstraction to preserve demo safety
- verification and redemption are separated in the merchant flow
- blocked redemption is stored as an off-chain audit event
- manual override is stored as off-chain approval plus on-chain override event logging semantics
- judge-safe wording should describe the ledger as a demo-safe representation of shared on-chain state

## Validation Run

- `node --check src/server.js`
- `node --check public/app.js`
- `node --check scripts/acceptance-check.js`
- `npm run test:acceptance`
- HTTP smoke checks for `/`, `/api/bootstrap`, and `/api/context`

## Competitiveness Call

Competitive, but not automatically winning.

Why it can win:

- clear institutional problem
- tight blockchain necessity
- demo-safe live flow
- non-crypto beneficiary UX

Why it can lose:

- if the story sounds like voucher management instead of shared trust state
- if the blockchain moment is not pointed out during redemption and audit

## 2026-04-11 Environment And UI Integration

- enabled and repaired WSL on the machine
- installed Ubuntu 24.04 under WSL
- installed WSL-side Rust, Node.js, Solana CLI, and Anchor CLI
- verified:
  - `solana-cli 3.1.13`
  - `anchor-cli 0.32.1`
  - `rustc 1.94.1`
  - `node 18.19.1`
- imported `mealtrust_app/` from `Charles_branch`
- kept the existing Node backend temporarily to avoid breaking the incoming Flutter UI
- added Flutter-compatible backend endpoints:
  - `GET /api/student/:studentId/voucher`
  - `GET /api/solana/status`
- updated issuer/redeem responses to include `onChain` placeholders expected by Flutter
- enriched audit and voucher payloads with `merchantId` and `studentId`
- removed stale Flutter widget test that referenced a deleted `MyApp`
- ran:
  - `flutter pub get`
  - `flutter analyze` (warnings only)
  - `npm run test:acceptance`

## Current Recommendation

- keep `mealtrust_app/` as the incoming UI surface
- keep the existing Node backend until the Solana-backed backend contract is in place
- do not delete `src/` or `public/` yet
- next technical step: add the minimal Anchor workspace and replace the local ledger boundary behind the existing API

## 2026-04-11 Anchor Integration Start

- added `anchor/` with one minimal program: `mealtrust_state`
- fixed the on-chain scope to exactly:
  - redeem checkpoint
  - revoke checkpoint
  - override event logging
- kept issuance explicitly off-chain in both the backend and contract plan
- added `src/lib/solana-ledger.js` as the backend integration seam
- updated backend responses so `redeem`, `revoke`, and `override` now come through the adapter path without changing the Flutter-facing API contract
- ran:
  - `node --check src/server.js`
  - `node --check src/lib/solana-ledger.js`
  - `node --check scripts/acceptance-check.js`
  - `npm run test:acceptance`
  - `cargo check` in `anchor/programs/mealtrust_state`
- started `anchor build` from WSL
  - the first run is slow because `cargo-build-sbf` bootstraps toolchain components
  - host-side contract compilation already passed with `cargo check`
  - the long SBF bootstrap was stopped after confirming the program shape is valid

## 2026-04-11 Next Manager Prompt Synthesis

- audited the latest repo and workspace state before drafting the next manager prompt
- identified that the older manager prompt is now stale in three important ways:
  - it still assumes broad MVP buildout work, but the MVP and judge package already exist
  - it still assumes no imported Flutter UI, but `mealtrust_app/` is now present
  - it still assumes the ledger should remain abstracted, but the current user objective is to introduce real Solana localnet integration
- documented the updated state in:
  - `workspace/repo_state_audit.md`
  - `workspace/manager_prompt_diff.md`
  - `workspace/next_manager_prompt.md`
- set the recommended next objective to:
  - complete localnet build/deploy
  - replace the Solana adapter stub with live calls
  - preserve the Flutter-facing backend contract

## 2026-04-11 Charles_Branch_2 Review And Integration

- reviewed `origin/Charles_Branch_2`
- rejected a full merge because the branch mixed useful auth work with a repo-wide rename from `MealTrust` to `NourishChain`
- kept the frozen product framing and anchor naming on `main`
- selectively integrated the useful parts:
  - backend bearer-token auth in `src/lib/auth.js`
  - role-protected backend routes in `src/server.js`
  - Flutter login/session layer in `mealtrust_app/lib/services/auth_service.dart`
  - Flutter login screen in `mealtrust_app/lib/screens/login_screen.dart`
  - auth-gated role routing in `mealtrust_app/lib/screens/home_screen.dart`
  - role-aware issuer / merchant / student / auditor screens
  - acceptance updates for authenticated flows and unauthorized merchant coverage
- preserved `merchant_not_approved` by adding a blocked merchant demo account bound to `CAF-X`
- reran validation:
  - `node --check src/server.js`
  - `node --check src/lib/auth.js`
  - `node --check scripts/acceptance-check.js`
  - `flutter analyze` in `mealtrust_app/`
  - `npm run test:acceptance`
- result:
  - the branch was good directionally
  - full merge was not accepted
  - selective integration into `main` was accepted

## 2026-04-11 Public UI Retirement

- removed the temporary `public/` web UI
- converted `src/server.js` from mixed API + static hosting to API-only mode
- kept `/` as a small JSON status endpoint so `npm start` still has an obvious health response
- switched repository instructions to:
  - `npm start` for backend
  - `flutter run` in `mealtrust_app/` for the UI
- confirmed that the project now treats Flutter as the primary UI surface

## 2026-04-11 Flutter Web Runtime Fallback

- investigated a Chrome debug failure in `mealtrust_app/`
- confirmed the app source is valid by running `flutter build web` successfully
- confirmed the failure is in the Chrome debug launcher path resolution, not in the app code
- added a runtime fallback in `src/server.js`:
  - if `mealtrust_app/build/web/index.html` exists, the backend now serves the built Flutter web app
  - if no build exists, `/` still returns API-only JSON guidance
- updated `README.md` to prefer:
  - `cd mealtrust_app && flutter build web`
  - `npm start`
  - open `http://localhost:3000`
- reran validation:
  - `node --check src/server.js`
  - `flutter build web`
  - `npm run test:acceptance`
