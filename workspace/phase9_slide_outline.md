# Phase 9 — Slide Outline

## Slide 1 — Problem

- University hardship meal support involves Student Affairs, merchants, and auditors
- The weak point is not voucher creation, but trusted redemption and revocation state
- The workflow becomes fragile when each actor depends on separate records

## Slide 2 — Without Shared State

- Same QR is shown at Cafeteria A and Cafeteria B
- One office log is updated later, but merchants act in real time
- Auditors see reconciliation work, not one neutral event trail

## Slide 3 — Who Suffers

- Student Affairs staff who issue and revoke support
- Campus cafeteria cashiers who need a fast yes/no answer
- Auditors who need a reliable history
- Eligible students who should not be forced through crypto UX

## Slide 4 — Solution

- Wallet-free QR voucher for one campus hardship program
- Merchant verify/redeem flow
- Auditor-visible event history
- Blockchain used only for revocation, redemption state, and audit checkpoints

## Slide 5 — Why Blockchain Here

- This is not about storing more data
- It is about preventing disputes between independent actors
- Off-chain data stays private; shared trust state stays minimal and append-only

## Slide 6 — Demo

- Student presents one QR pass
- Cafeteria A redeems it successfully
- Cafeteria B tries the same QR seconds later and is blocked
- Auditor sees the same event trail immediately

## Slide 7 — Pilot Path

- Pilot one campus with Student Affairs and 1–2 cafeterias
- Keep eligibility off-chain and staff-owned
- Start with a web verify screen, not POS integration

## Slide 8 — Broader Impact

- Same trust pattern can support scholarships
- Same trust pattern can support emergency aid
- Same trust pattern can support NGO food distribution
- Same trust pattern can support disaster relief

## Slide 9 — Responsible Design

- No wallet required
- Personal data off-chain
- Manual override is human-controlled and logged
- Offline, biometrics, and complex integrations are out of scope

## Slide 10 — Closing

- This is a shared trust layer, not a voucher app
- The team proved the minimum viable trust state
- Ask: pilot this with one university program
