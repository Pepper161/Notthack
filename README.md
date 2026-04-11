# Notthack

`NourishChain` is the current project name for this demo.

This repository contains a judge-ready local demo for the BGA Track at NottsHack:

- a wallet-free QR benefit flow for one university hardship support program
- an issuer flow for Student Affairs
- a merchant verify and redeem flow for approved campus cafeterias
- an auditor-visible history of meaningful events
- a narrow blockchain-style trust layer for redemption, revocation, and audit checkpoints
- a Flutter app as the primary UI surface

![NourishChain demo UI](docs/assets/mealtrust-demo.png)

## What This Project Is

This is **not** a general voucher platform and **not** a crypto onboarding product.

It is a **shared trust layer** for one narrow workflow:

- Student Affairs decides eligibility off-chain
- a student receives a QR-based support credential
- a cafeteria cashier verifies and redeems it
- an auditor can inspect issued, redeemed, blocked, revoked, and override events

The student experience is wallet-free.

## The Problem

The project is built around one practical coordination problem:

- issuers, merchants, and auditors all depend on the same redemption and revocation state
- those records are often fragmented across separate systems
- that creates cross-merchant duplicate-redemption risk, revoked-voucher misuse, and weak auditability

This repo uses a university hardship support workflow as a **pilotable deployment context** for that broader benefit-delivery trust problem.

## Why Blockchain Here

Blockchain is used only for the minimum shared trust state:

- redemption state
- revocation state
- audit checkpoints
- override event logging

Blockchain is **not** used for:

- hardship eligibility assessment
- student identity storage
- payment settlement
- merchant onboarding
- replacing university databases

## Important Demo Note

The current implementation uses a **demo-safe local ledger abstraction**, not a deployed smart contract.

That means:

- the trust model is explicit
- state transitions are enforced
- the demo is stable for live presentation

It does **not** mean this repo already ships a real Solana or EVM deployment.

## Demo Capabilities

The local demo supports:

1. voucher issuance or seeded issuance
2. wallet-free student QR presentation
3. merchant verify
4. merchant redeem
5. cross-merchant duplicate redemption block
6. revoked voucher block
7. unauthorized merchant block
8. auditor visibility into meaningful history

## Tech Stack

- Flutter app in `mealtrust_app/`
- Node.js / Express backend in `src/`
- Anchor workspace in `anchor/`
- local runtime state stored in `src/data/runtime-state.json`

## Run Locally

### Requirements

- Node.js 20+ recommended

### Install

```bash
npm install
```

### Start the backend

```bash
npm start
```

The backend listens on:

```text
http://localhost:3000
```

### Build the Flutter web UI

```bash
cd mealtrust_app
flutter build web
```

### Start the backend and serve the built UI

```bash
cd ..
npm start
```

Then open:

```text
http://localhost:3000
```

### Optional: run Flutter in Chrome debug mode

```bash
cd mealtrust_app
flutter run -d chrome
```

### Run acceptance checks

```bash
npm run test:acceptance
```

## Suggested Demo Path

Use the app in this order:

1. Open the issuer panel and keep or issue a voucher for a seeded student.
2. Show the student QR pass.
3. On the merchant panel, use `CAF-A` to verify and redeem `VCH-1001`.
4. Switch to `CAF-B` and try the same voucher again.
5. Show the cross-merchant duplicate-redemption block.
6. Optionally verify a revoked voucher or an unauthorized merchant.
7. Open the auditor panel and show the shared history.

## Repository Structure

- `src/` — backend server and state logic
- `mealtrust_app/` — primary Flutter UI and web build source
- `anchor/` — minimal Solana / Anchor trust-layer scaffold
- `scripts/` — acceptance checks
- `docs/` — concept notes and team-share docs
- `workspace/` — planning, strategy, pitch, and execution logs

## Key Docs

- [Team Share](docs/BGA_Team_Chat_Share.md)
- [Idea Rationale With Sources](docs/BGA_Team_Idea_Rationale_With_Sources.md)
- [Winning Workflow](docs/BGA_NottsHack_Winning_Workflow.md)
- [Pitch Checklist](docs/PITCH_CHECKLIST.md)
- [Manager Execution Summary](workspace/manager_execution_summary.md)

## Current Status

Implemented:

- local backend
- Flutter UI with role-based login
- merchant verify/redeem flow
- issuer issue/revoke/override flow
- student wallet-free QR pass
- auditor history view
- acceptance checks
- pitch and submission planning docs

Deferred on purpose:

- real student information system integration
- real payment or POS integration
- offline mode
- multi-university support
- full DID stack
- biometrics
- analytics dashboards
- mobile-native apps

## Project Framing

If you are presenting this project, use this framing:

> This is not a voucher app on blockchain.
> It is a minimal shared trust layer for redemption, revocation, and audit state in one university hardship support workflow.
