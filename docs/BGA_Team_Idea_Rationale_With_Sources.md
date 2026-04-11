# BGA Idea Rationale With Sources

## Executive Summary
Our current concept is a **university hardship support credential MVP**.
It is designed as a **pilotable version of a broader real-world aid and benefit delivery problem**:
multiple parties need to trust the same redemption and revocation state, but records are often fragmented.

This is why the concept is strong:

- the user roles are concrete
- the operational problem is real
- the MVP is narrow
- the blockchain role is limited and defensible
- the student experience stays wallet-free

## 1. The real problem we are anchoring to
The exact university scenario is our deployment context, not the only source of truth.
The stronger claim is that **benefit delivery systems commonly face trust and verification problems** across identity, entitlement, redemption, reconciliation, and audit.

### Evidence A: identity and inclusion are still major barriers
The World Bank ID4D 2024 report says that around **800 million people still do not have official proof of identity**, and **2.9 billion people do not have a digital identity**.
This matters because poor identity infrastructure makes benefit delivery, entitlement checks, and service access much harder.

Source:
- https://id4d.worldbank.org/annual-report/2024

### Evidence B: cash and voucher assistance is already a major real-world operating model
The World Food Programme reports that in 2023 it supported **51.6 million people** through cash-based transfers.
This is relevant because it shows that voucher and benefit redemption workflows are not hypothetical edge cases; they are large operational systems.

Source:
- https://www.wfp.org/cash-transfers

### Evidence C: fragmented tracking and payment assurance are known operational pain points
WFP’s Payment Instrument Tracking project describes a legacy process based on paper forms and spreadsheets, and explicitly frames the effort as improving visibility, traceability, reconciliation, and assurance in cash assistance operations.
That is very close to the trust problem we are targeting: not “send money,” but “maintain trusted shared operational state.”

Source:
- https://innovation.wfp.org/project/payment-instrument-tracking

### Evidence D: blockchain has already been explored in aid delivery when multi-party trust matters
Rahat, developed by Rumsan, is a public example of blockchain-based aid distribution infrastructure focused on transparency and immutable process records.
We are not copying Rahat, but it helps validate that the underlying design space is real.

Source:
- https://rumsan.com/portfolio/rahat

## 2. Why a university hardship support workflow is a good pilot context
We chose the university context because it is easier to explain, safer to demo, and more concrete than a broad NGO platform.

It gives us four clear actors:

- **Issuer**: Student Affairs Office
- **Beneficiary**: eligible student
- **Merchant**: approved cafeteria cashier
- **Auditor**: finance or compliance reviewer

This is strong for a hackathon because each actor has a clear job and a clear failure mode.

### Student story
An eligible student needs quick access to meal support without learning crypto or handling a wallet.
They should just present a QR code and get a yes/no answer fast.

### Merchant story
A cashier needs to know whether a support credential is valid **right now**.
They should not read hardship reasons, access student records, or guess whether the same QR was already redeemed at another cafeteria.

### Issuer story
Student Affairs makes the eligibility decision before issuance and can later revoke a support credential if needed.
They need confidence that revocation and redemption status are consistently enforced downstream.

### Auditor story
An auditor needs to see a meaningful history of issued, redeemed, blocked, revoked, and override events.
They need more than editable departmental logs.

## 3. Why this is not “just another voucher app”
The novelty is not the QR code.
The novelty is the **shared trust layer**.

Most normal voucher apps are built around one operator owning the entire system.
Our framing is different:

- issuer decides eligibility off-chain
- merchant checks a narrow validity signal
- auditor inspects history later
- blockchain is used only for the state all three parties must trust together

That is why the core product claim is:

> We are not building a general aid platform.
> We are building the minimum shared trust state for a university hardship support workflow.

## 4. Exactly what blockchain does here
Blockchain is used only for:

- revocation state
- redemption state
- audit checkpoints
- manual override event logging

Blockchain is not used for:

- hardship eligibility assessment
- student identity storage
- payment processing
- merchant onboarding
- full university system replacement

This narrow scope is intentional.
It makes the “why blockchain?” argument much stronger.

## 5. The strongest “why blockchain?” answer
If one office owns the only database, the other parties still have to trust that office’s logs after the fact.
That is weak exactly in the cases that matter most:

- disputed redemption
- revoked voucher misuse
- cross-merchant duplicate redemption claims
- manual exception handling
- audit and reconciliation

A shared ledger is useful here because it gives the program a **common state checkpoint** across issuer, merchant, and auditor without exposing private student data.

## 6. What we should say to teammates
Use this wording:

> Our idea is a wallet-free hardship meal voucher system for one university.
> The student just shows a QR code.
> The real product is the trust layer underneath: Student Affairs, cafeteria staff, and auditors all need a shared, tamper-resistant view of redemption and revocation status, while keeping eligibility details and personal data off-chain.

Recommended tighter wording:

> Our idea is a wallet-free support credential system for one university hardship program.
> The student just shows a QR code.
> The real product is the trust layer underneath: Student Affairs, cafeteria staff, and auditors all need a shared, tamper-resistant view of redemption and revocation status, while keeping eligibility details and personal data off-chain.

## 7. Team-facing conclusion
The idea is valid because:

- the underlying operational problem is real
- the user roles are believable
- the MVP is small enough for a hackathon
- the blockchain scope is narrow enough to defend
- the demo clearly shows why a shared trust state matters

The university setting is our **pilot context**, not a claim that every campus already runs this exact workflow.
That makes the concept both honest and practical.
