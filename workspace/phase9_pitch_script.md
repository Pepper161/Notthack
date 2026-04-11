# Phase 9 — Pitch Script

## 0:00-0:20

University hardship meal support looks simple, but the trust problem is not. Student Affairs issues support, campus merchants redeem it, and auditors must later verify that the same voucher was not used twice and was not redeemed after revocation.

## 0:20-0:40

Without a shared redemption state, one student can screenshot the same QR and try it at two cafeterias. Even if one office keeps a database, the merchant and the auditor still depend on separate, editable logs and delayed reconciliation.

## 0:40-1:00

We built a wallet-free QR benefit flow for one campus. The student only shows a QR pass, the merchant gets a fast yes or no, and the auditor sees the same event trail that Student Affairs sees.

## 1:00-1:20

Blockchain is used only where the trust problem actually lives: redemption state, revocation state, and audit checkpoints. We do not put student identity, hardship reasons, or payment settlement on-chain, because this is not about storing more data. It is about preventing disputes between independent actors.

## 1:20-1:40

In the demo, Cafeteria A redeems one voucher successfully. Seconds later, Cafeteria B tries the same QR and gets blocked because the shared state already says redeemed. That is the core value: one state, shared across Student Affairs, merchants, and auditors.

## 1:40-2:00

This can pilot on one campus with one Student Affairs office and one or two cafeterias. The same trust pattern can later support scholarships, emergency aid, NGO food distribution, or disaster relief. It is responsible by design, practical for non-crypto users, and intentionally narrow enough to pilot safely.
