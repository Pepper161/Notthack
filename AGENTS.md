# AGENTS.md

## Mission
Optimize for winning the BGA Track at NottsHack with a practical, demo-safe, judge-friendly implementation.

## Current Product Thesis
Build a minimal shared trust layer for a university hardship meal voucher program on one campus.

The product is:
- a wallet-free QR voucher for eligible students
- a merchant verify/redeem flow
- a narrow blockchain trust layer for revocation, redemption state, and audit checkpoints
- an auditor-visible history of key events

The product is **not**:
- a general aid platform
- a donation platform
- a crypto onboarding product
- a tokenized rewards system
- a national identity system

## Priority Order
1. Real-world problem clarity
2. Blockchain necessity
3. Practicality
4. Impact potential
5. UX for non-crypto users
6. Responsible design
7. Clear path to deployment
8. Demo reliability
9. Scope discipline

## Frozen Deployment Context
One university hardship meal voucher program for one campus, redeemable at approved campus cafeterias.

## Minimum Actor Model
1. Issuer — University Student Affairs Office
2. Beneficiary — eligible student
3. Merchant — approved campus cafeteria cashier
4. Auditor — university finance / compliance reviewer

## Core Design Rules
- Keep blockchain scope narrow.
- Store only the minimum shared trust state on-chain.
- Keep all personally identifying and sensitive eligibility data off-chain.
- Keep the student experience wallet-free.
- Favor demo-safe implementation over architectural ambition.

## Blockchain Scope
Blockchain is used only for:
- revocation state
- redemption state
- audit checkpoints
- override event logging

Blockchain is not used for:
- hardship eligibility assessment
- student identity storage
- payment settlement
- merchant onboarding
- full university database replacement

## Redemption-Time Rule
Eligibility is decided by Student Affairs before issuance or revocation.

At redemption time, the merchant flow checks only:
1. merchant approval off-chain
2. voucher existence off-chain
3. on-chain state summary

The merchant flow must not:
- recompute hardship eligibility
- read hardship assessment reasons
- access full student records

## Voucher State Model
Only these main states exist:
- active
- revoked
- redeemed

Rules:
- `override_logged` is not a main state; it is a separate audited event.
- `voucher_redemption_blocked` is an off-chain audit event, not a main on-chain state change.

## Validity Rule For MVP
If `issueVoucher` remains off-chain for MVP, then a voucher is valid before first redemption when:
- merchant is approved off-chain
- voucher exists off-chain
- on-chain state is neither revoked nor redeemed

`unknown_voucher` means off-chain voucher lookup failed.

## Anti-Patterns
- Generic donation transparency
- Wallet-first UX for normal users
- Token mechanics without need
- Vague target users
- Decorative blockchain usage
- Overbuilt MVP scope
- Full DID theater without demo value
- Analytics or dashboard work that does not strengthen the demo
- Any feature that makes the demo harder to finish

## Mandatory Demo Path
The demo should support:
1. voucher issuance or seeded issuance
2. wallet-free student QR presentation
3. merchant verify
4. merchant redeem
5. duplicate redemption block
6. revoked voucher block
7. unauthorized merchant block
8. auditor visibility of meaningful history

## Build Order
Follow this order unless there is a strong reason not to:
1. shared state model
2. verify / redeem backend flow
3. merchant UI
4. revoke / override backend
5. issuer UI
6. student QR pass
7. auditor view
8. demo polish
9. acceptance validation

## Acceptance Priorities
First priority:
- happy path verify
- happy path redeem
- duplicate-redemption block
- revoked-voucher block
- unauthorized-merchant block

Second priority:
- auditor visibility
- override logging

## Explicit Deferrals
Do not build these unless absolutely necessary:
- real student information system integration
- real payment or POS integration
- offline redemption mode
- multi-university support
- full DID stack
- biometrics
- mobile-native apps
- analytics dashboards
- complex merchant onboarding
- automated fraud scoring

## Working Style
- Write intermediate outputs to `workspace/`
- Record assumptions explicitly
- Reject weak or bloating ideas early
- Prefer concrete institutions, users, and deployment paths
- Prefer fake but believable local data over risky real integrations
- When uncertain, make the smallest reasonable assumption and continue
- Keep outputs concise, structured, and decision-oriented

## Manager Mode
When a task is large enough to benefit from decomposition, do not operate as a single worker only.

Act as a manager agent:
- split work into sub-tasks or sub-agents when helpful
- run safe workstreams in parallel
- define clear ownership for each workstream
- integrate and reconcile outputs yourself
- resolve conflicts across workstreams before finalizing
- keep a short manager execution summary in `workspace/manager_execution_summary.md`
- prefer progress over waiting for human intervention

## Sub-Agent / Workstream Policy
Create sub-agents or parallel workstreams when at least one of the following is true:
- work can be separated by component boundary
- backend and UI can progress independently
- implementation and validation can progress independently
- seed data or audit view can be prepared without blocking core logic
- one stream can continue while another is waiting on integration

For each sub-agent or workstream, define:
- goal
- owned files or components
- required inputs
- expected outputs
- stop condition

Before merging outputs:
- check naming consistency
- check state-model consistency
- check API contract compatibility
- check demo-flow consistency
- keep the smallest solution that preserves the frozen thesis

## Default Technical Bias
Prefer:
- one simple contract
- one backend service
- one QR format
- one merchant verification path
- local seed data
- minimal moving parts

Avoid:
- multi-contract design
- fragile async dependencies
- unnecessary external integrations
- architecture that looks impressive but weakens demo safety

## Reporting Requirement
Maintain:
- `workspace/run_log.md`
- `workspace/manager_execution_summary.md`

The manager summary should include:
- workstreams created
- assumptions made
- files changed
- tests or checks run
- remaining risks
- exact demo path

## Scope Guardrail
If a feature does not make the happy path or duplicate-redemption failure more credible in the demo, do not build it now.

## Done Condition
The task is done when:
- the local demo is runnable
- merchant verify/redeem works
- duplicate redemption is blocked
- revoked voucher is blocked
- unauthorized merchant is blocked
- student flow remains wallet-free
- auditor can inspect meaningful history
- scope remains narrow and judge-friendly