# Manager Prompt Diff

## Previous Prompt Focus

The previous manager prompt was optimized for:

- building the smallest demo-safe implementation
- filling all major product surfaces
- producing judge strategy, demo polish, pitch narrative, Q&A defense, and submission planning

That prompt assumed:

- there was no imported Flutter UI yet
- there was no Anchor workspace yet
- the project still needed broad UI and judge-package buildout
- the chain layer would likely remain a local abstraction

## What Changed

### Change 1: The repo now already has a real Flutter UI

New fact:
- `mealtrust_app/` exists and is connected to the backend contract

Why this matters:
- the next run should not spend time rebuilding issuer / merchant / student / auditor UI from scratch
- the next run should preserve the current API contract and use Flutter as the forward UI direction

Older wording that should no longer be trusted:
- any prompt wording that treats UI implementation as the main missing workstream

### Change 2: The repo now already has an Anchor workspace

New fact:
- `anchor/` exists
- `mealtrust_state` already defines the narrow state shape

Why this matters:
- the next run should not start from chain design ideation
- the next run should focus on build, deploy, integration, and validation

Older wording that should no longer be trusted:
- any wording that says “decide whether to add a contract” or “design the minimal contract surface” as if that work is still pending

### Change 3: The backend now has a Solana adapter seam

New fact:
- `src/lib/solana-ledger.js` exists
- routes already pass through it

Why this matters:
- the next run should not redesign backend boundaries
- it should replace the adapter stub with real localnet calls

Older wording that should no longer be trusted:
- any wording that treats the backend as directly tied to the local ledger with no migration seam

### Change 4: Judge strategy docs are already complete

New fact:
- Phase 7, 8, and 9 docs exist

Why this matters:
- the next run should not spend most of its effort on pitch, Q&A, or slide generation
- those docs should only be updated if the new chain implementation materially changes the story

Older wording that should no longer be trusted:
- prompts that still list judge package creation as a primary mandatory workstream

### Change 5: User intent has changed from “demo-safe only” to “introduce real Solana”

New fact:
- the user explicitly said they want to introduce the real Solana chain

Why this matters:
- the next manager prompt must treat localnet integration as the active objective
- it must explicitly explain how to handle conflict with older docs that recommended keeping the ledger abstracted

Older wording that should no longer be trusted:
- “do not add a real-chain checkpoint”
- “keep the local ledger abstraction as-is”

## Why Each Change Was Necessary

1. To stop repeating already-completed implementation work.
2. To avoid wasting a run on stale planning tasks.
3. To preserve the existing Flutter/backend contract rather than breaking it.
4. To align execution with the latest user direction.
5. To make the next Codex run directly executable without more human context.

## New Prompt Design Principles

The next manager prompt must:

- preserve frozen thesis and scope boundaries
- treat Flutter as the intended app UI
- treat Node backend as the current API surface that must stay stable
- treat Anchor + localnet as the next technical objective
- require real-chain validation, not just docs
- assume Flutter web served by the backend is already the active local demo path

## What Older Wording Should No Longer Be Trusted

- “Build the smallest demo-safe implementation” as the primary objective
- “Do not add a real-chain checkpoint”
- “Mandatory workstreams include full pitch package generation”
- “Merchant UI / issuer UI / student pass / auditor view still need to be created”
- “The main chain decision is whether to use blockchain at all”

Those assumptions are now stale because the product, repo, and user intent have already moved past them.
