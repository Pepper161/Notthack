# BGA Track Team Share

## 1. What we are building
We are building a **wallet-free QR support credential trust layer** for **one university hardship support program**.

The goal is not to build a general aid platform or a crypto product.
The goal is to solve one narrow but important trust problem:

- Student Affairs decides eligibility and issues or revokes support credentials
- Campus cafeterias need to quickly verify whether a credential is valid
- Auditors need a reliable history of what was issued, redeemed, blocked, revoked, or manually overridden

In our MVP, the student just shows a QR code.
No wallet, no token management, no crypto knowledge.

## 2. The problem we are solving
In benefit and voucher programs, the most fragile part is often not the UI.
It is the **shared state** between multiple parties:

- Is this credential still active?
- Has it already been redeemed elsewhere?
- Was it revoked?
- Can we prove later who changed what and when?

If these records are fragmented across issuer systems, merchant systems, and audit logs, teams get:

- cross-merchant duplicate redemption risk
- revoked voucher misuse
- inconsistent records across departments
- expensive or weak audits
- more friction for the people who actually need support

## 3. Why this matters
We are not claiming that every university already runs this exact blockchain flow.
Our claim is narrower and more defensible:

**real benefit-distribution systems already struggle with identity, verification, fragmented records, and auditability**

We are taking that real trust problem and turning it into a **pilotable university use case** that is easy to understand and demo.

## 4. Why blockchain is used here
We are using blockchain only for the **minimum shared trust state**:

- redemption state
- revocation state
- audit checkpoints
- override event logging

We are **not** using blockchain for:

- hardship assessment
- student identity storage
- payment settlement
- replacing university databases

So the pitch is:

> This is not “a voucher app on blockchain.”
> It is a minimal trust layer for the one part of the workflow that multiple parties need to trust together.

## 5. Why this is a good BGA Track fit
This matches the BGA judging direction because it is:

- based on a real-world coordination problem
- practical and narrow enough for a hackathon
- usable by non-crypto users
- defensible on “why blockchain?”
- easy to explain with a short demo

## 6. Demo scope
Our local demo already focuses on the core path:

1. voucher issuance or seeded issuance
2. wallet-free student QR presentation
3. merchant verify
4. merchant redeem
5. cross-merchant duplicate redemption blocked
6. revoked voucher blocked
7. unauthorized merchant blocked
8. auditor sees meaningful history

## 7. Sources behind the problem framing
These are the main public references supporting the broader problem:

- World Bank on digital public infrastructure and inclusion:
  https://www.worldbank.org/en/results/2023/10/12/creating-digital-public-infrastructure-for-empowerment-inclusion-and-resilience
- World Bank ID4D on the global identity gap:
  https://id4d.worldbank.org/annual-report/2024
- WFP on large-scale cash and voucher assistance:
  https://www.wfp.org/cash-transfers
- WFP on payment instrument tracking and assurance gaps:
  https://innovation.wfp.org/project/payment-instrument-tracking
- Rahat / Rumsan as a real blockchain-based aid distribution example:
  https://rumsan.com/portfolio/rahat

## 8. One-sentence summary
We are building a wallet-free university support credential system that keeps personal data off-chain, while using blockchain only for the shared redemption, revocation, and audit state that issuers, merchants, and auditors all need to trust.
