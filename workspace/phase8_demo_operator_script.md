# Phase 8 — Demo Operator Script

## 90-120 Second Script

### 0-10 sec

`This is a university hardship meal support workflow. The risk is not voucher creation. The risk is whether Student Affairs, campus merchants, and auditors all trust the same redemption and revocation state.`

### 10-20 sec

Say:

`Without that shared state, the same QR can be shown at two cafeterias and the dispute is only discovered later.`

### 20-30 sec

Open the Student tab and show the QR pass.

Say:

`The student never touches a wallet. They only present a QR credential.`

### 30-50 sec

Switch to Merchant.

Select `CAF-A` and `VCH-1001`.

Click `Verify`, then `Redeem`.

Say:

`At checkout, we only check merchant approval, voucher existence, and the shared state. We do not re-evaluate hardship eligibility here.`

### 50-60 sec

Show the checkpoint or audit marker.

Say:

`This redemption is now recorded as a shared checkpoint. Student Affairs and auditors see the same event trail.`

### 60-80 sec

Stay on Merchant, switch to `CAF-B`, keep the same voucher, and click `Verify` or `Redeem` again.

Say:

`Now a second cafeteria tries the same QR a few seconds later. It is blocked because the shared state already says redeemed. This is the cross-merchant trust moment.`

### 80-95 sec

Switch to Auditor.

Show issued, redeemed, and blocked events.

Say:

`That is the trust layer: one state, one history, multiple actors. Not separate editable logs.`

### 95-110 sec

If needed, show a revoked voucher or unauthorized merchant.

Say:

`We also block revoked vouchers and merchants who are not approved.`

### 110-120 sec

Close with pilot path.

Say:

`This can pilot on one campus with Student Affairs, one or two cafeterias, and finance review. The same trust pattern can later support scholarships, emergency aid, and NGO distribution workflows.`

## Operator Rules

- Start from reset state every time.
- Keep `VCH-1001` as the main happy-path voucher.
- Redeem first with `CAF-A`.
- Use `CAF-B` for the second attempt so the cross-merchant sync is visible.
- Keep `CAF-X` ready for the unauthorized-merchant proof.
- Do not explain blockchain internals unless asked.
- Do not call this a platform during the main demo. Call it a shared trust layer or a trust pattern.
