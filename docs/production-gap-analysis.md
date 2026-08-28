# Production gap analysis — Atlas Forge RWA

**ATLAS FORGE RWA PUBLIC TESTNET ENGINEERING REHEARSAL.**
This work does not represent a live security, investment product, USD-backed
asset, audited protocol, KYC platform, or production issuance.

This document splits what a public Sepolia rehearsal can demonstrate from what
is still required before anyone could treat this shape as mainnet or real-world
asset (RWA) infrastructure. It does **not** classify the token under securities
law. That is a legal question, not a Solidity question.

The v1 trust model is intentional: `DEFAULT_ADMIN`, `ISSUER`, `FREEZER`, and
`RECOVERY` are product capabilities (issuer-is-god), not hidden vulnerabilities.
See `docs/threat-model.md` and AFR-04 through AFR-11.

## PUBLIC TESTNET COMPLETE (engineering rehearsal)

These items are in-repo and can be exercised on Sepolia **after** a real
broadcast (this PR does not broadcast):

| Item | Status |
| --- | --- |
| Permissioned ERC-20 `_update` hook on user transfer / mint / burn | Implemented (`src/PermissionedToken.sol`) |
| Identity registry (`isVerified` + `bytes32` attestation commitment, not PII) | Implemented |
| Freeze / unfreeze (FREEZER); no supply change | Implemented |
| `forceTransfer` recovery bypass (RECOVERY or ISSUER); supply-preserving | Implemented; documented AFR-06 |
| Compliance knobs: max-balance, optional tag allowlist (demo/test policy codes) | Implemented; not sanctions/accreditation |
| AccessControl roles granted in constructors | Implemented (AFR-02 fix) |
| Foundry unit / fuzz / invariant suites | Implemented; see `artifacts/local-ci/` |
| Deploy + smoke scripts with keystore signing (`--account`, not `--private-key`) | Tooling in this branch |
| AFPT / Atlas Forge Permissioned Test Token labeling on the documented testnet path | `.env.example` + script README |
| Evidence templates (no fabricated hashes/addresses) | `artifacts/*schema.json`, `deployments/sepolia.example.json` |

A passing local `forge test` and a future Sepolia smoke **do not** make this a
product.

## MAINNET / REAL RWA NOT READY

| Gap | Why it is not optional for real RWA | What this repo has |
| --- | --- | --- |
| **Admin timelock / multisig** | DEFAULT_ADMIN can grant every role immediately. Compromise is instant. | Single EOA admin (AFR-07). atlas-forge-vault shows a 48h pattern; not duplicated here. |
| **Role separation** | ISSUER mint/burn/`forceTransfer`, FREEZER halt, RECOVERY seize must be independent keys and people. | Constructors *can* take distinct addresses. Deploy `envOr` defaults overlap onto ADMIN. Smoke allows `ACK_ROLE_OVERLAP=true` for faucet limits. |
| **Hardware keys** | Operational roles must not live in a software keystore on a laptop. | Docs tell operators to use `--account` / hardware (`--ledger` / `--trezor` exist in Foundry). Not enforced. |
| **Professional audit** | Restriction + recovery tokens are high-impact. Internal notes are not an audit. | Internal A5 notes in `docs/findings/` (no Critical/High claimed). **Not a paid audit.** |
| **Formal verification** | Invariants (supply conservation, freeze, registry) should be machine-checked beyond fuzz. | Foundry invariants with `fail_on_revert = false` (accepted residual). No Certora/Halmos harness in this repo. |
| **Pause / emergency** | Need a scoped circuit breaker for unforeseen integration bugs without relying only on freeze-everyone. | No pause. FREEZER can halt user paths per account; ISSUER remains god. |
| **Upgradeability** | Fixing a live token without migration is a product decision with its own trust. | No proxy. Immutable constructors. A fork would need an explicit proxy + timelock design. |
| **Monitoring** | Need alerts on mint, `forceTransfer`, role changes, freeze spikes. | No bot, no indexer, no on-call. |
| **Incident response** | Runbooks, key compromise procedures, communication templates. | Threat model only. |
| **Bug bounty** | Unpaid reviewers will not cover the loss surface of a live RWA token. | None. |
| **KYC / KYB** | `attestationHash` is an issuer-chosen `bytes32`. The chain cannot tell whether a person or entity was identified. | Not a KYC vendor integration. Tests lock listing, not identity truth. |
| **Sanctions screening** | Tag allowlist is a demo `bytes32` switch. It is not OFAC, not geofencing, not a travel-rule implementation. | Explicit non-goal. Smoke uses `ATLAS_TEST_POLICY_TAG_*` only. |
| **Credential revocation** | Delist (`setVerified(false)`) blocks user send/receive; balances remain until burn/`forceTransfer`. Off-chain credential lifecycle is absent. | On-chain delist only. |
| **Privacy** | Putting PII on-chain would be malpractice. This contract stores hashes only; off-chain stores, access control, and retention are unbuilt. | `bytes32` only. No PII schema. |
| **Asset custody** | A permissioned ERC-20 does not hold the underlying asset. | No vault, custodian adapter, or proof-of-reserve. |
| **Legal entity / SPV** | Issuance, if it ever happened, needs an issuer entity, offering docs, and (often) an SPV. | None. Author is a portfolio sketch. |
| **Transfer agent** | Cap tables, corporate actions, investor support. | Issuer EOA is not a transfer agent. |
| **Securities-law review** | Whether a token is a security, who may hold it, and where it may be offered is counsel work. | **Do not try to solve legal classification in code.** This repo does not. |
| **Reserve / NAV / oracle** | AFPT is a label. There is no dollar, NAV feed, or reserve attestation. | No oracle. Do not invent TVL/AUM/NAV. |
| **Redemption / corporate actions** | Real RWA needs redeem, dividend, split, and snapshot flows. | Issuer `burn` is not redemption. No snapshots. |

## Residual design that must stay labeled (not “fixed” as vulns)

- Issuer-is-god (AFR-04)
- Mint/burn skip verified-registry (AFR-05)
- `forceTransfer` bypasses freeze, registry, cap, tags (AFR-06)
- Per-contract `ISSUER_ROLE` storage (AFR-09)
- `transferFrom` gates `from`/`to`, not spender (AFR-10)
- `tagsEnforced` default-denies the zero tag (AFR-11)
- `[profile.intense.invariant] fail_on_revert = false` — Foundry continues invariant runs when a handler call reverts; handlers already assert conservation on success. Left unchanged.

## Honest eight-minute read

Not deployed. Not a product. Not an audit. Not ERC-3643. Not USD. Not KYC.
A future Sepolia smoke would still be an engineering rehearsal.
