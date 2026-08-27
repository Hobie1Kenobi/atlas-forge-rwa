# Threat model — Atlas Forge RWA

**Status:** v1 architecture, not an audit report. No audit has been performed. This document describes intended trust boundaries and residual risk so a reviewer can map tests to code.

**Scope:** `PermissionedToken` + `IdentityRegistry` + `Compliance`. Demo tags and attestation hashes are **not** a KYC, sanctions, or transfer-agent system.

This is **not** legally compliant securities infrastructure, **not** a broker-dealer product, **not** ERC-3643 certified, and **not** a KYC vendor integration.

## System boundary

```
Holders ──transfer / transferFrom──► PermissionedToken._update
                                        │
                                        ├─ frozen[from] / frozen[to]     (revert)
                                        ├─ IdentityRegistry.isVerified   (user path)
                                        └─ Compliance.validateTransfer   (max-balance, optional tags)

Issuer paths (intentional god-mode):
  ISSUER.mint / ISSUER.burn     skip verified-registry
  RECOVERY|ISSUER.forceTransfer skip verified, freeze, max-balance, tags
                                never mint/burn; totalSupply unchanged
  FREEZER.freeze / unfreeze     no balance movement; totalSupply unchanged
```

`attestationHash` is a `bytes32` stored next to `verified`. The contract never sees a name, document, or jurisdiction. Treating that hash as “KYC done” is an off-chain process failure, not something this code can enforce.

## Actors

| Actor | Trust | Capabilities |
| --- | --- | --- |
| Holder | Untrusted | `transfer` / `approve` / `transferFrom` if verified and not frozen |
| ISSUER | Fully trusted for supply and listing | `mint`, `burn`, `setVerified`, compliance knobs, `forceTransfer` |
| FREEZER | Trusted to halt user movement | `freeze` / `unfreeze`. Cannot mint, burn, or `forceTransfer` |
| RECOVERY | Trusted to seize/reassign balances | `forceTransfer` only. Cannot mint or burn |
| DEFAULT_ADMIN | Trusted to grant the roles above | `grantRole` / `revokeRole`. v1 is a single EOA; production should be a timelock |
| Attestation issuer (off-chain) | Out of scope | Whoever produced the hash. The chain cannot verify them |

## Admin powers (issuer-is-god)

Freeze and `forceTransfer` are not silent backdoors. They are the product:

| Action | Who | Changes supply? | User-path checks |
| --- | --- | --- | --- |
| `mint` | ISSUER | yes, up | skip verified on `to`; freeze and compliance still apply |
| `burn` | ISSUER | yes, down | skip verified on `from`; freeze still applies (unfreeze then burn) |
| `forceTransfer` | RECOVERY or ISSUER | **no** | **all skipped** except ERC-20 balance |
| `freeze` / `unfreeze` | FREEZER | **no** | n/a |
| `setVerified` | ISSUER | no | n/a |
| `setMaxBalance` / tags | ISSUER | no | n/a |
| Grant/revoke roles | DEFAULT_ADMIN | no | n/a |

A compromised ISSUER can inflate supply and move any balance, including to an unverified address. A compromised FREEZER can freeze every holder; users cannot exit on the user path until unfrozen, but RECOVERY can still `forceTransfer`. A compromised RECOVERY can drain any account onto an address they control. A compromised DEFAULT_ADMIN can grant themselves every role.

That is permissioned RWA. If you need an exit window against a malicious upgrade or role change, put DEFAULT_ADMIN on a timelock (see atlas-forge-vault). This repo does not duplicate a 48h timelock.

## Freeze vs recovery

- Frozen cannot **send or receive** on `transfer` / `transferFrom`.
- Frozen cannot **receive mint** or **be burned**.
- Frozen **can** be the `from` or `to` of `forceTransfer`. That is how lost-key / court-order recovery is modeled here: the freezer stops the compromised wallet; recovery pushes tokens to a replacement wallet that the issuer listed.

Do not read “frozen cannot send or receive” as “balances are immovable.” They are immovable *to users*. The issuer remains god.

## Identity is a list, not KYC

`setVerified(account, bool, attestationHash)` writes two fields. Tests lock that unauthorized callers revert and that `address(0)` cannot be listed. Tests do **not** lock that the hash corresponds to a real person. Nothing on-chain can.

Delisting (`verified = false`) immediately blocks user send and receive. Existing balances stay put until `forceTransfer` or issuer `burn` (if not frozen).

## Compliance knobs

- `maxBalance == 0` → uncapped. Otherwise `balanceOf(to) + amount` must be `<= maxBalance` on mint and user transfer.
- `tagsEnforced == false` (default) → tags may be stored and are not checked.
- `tagsEnforced == true` → both `from` and `to` need `allowedTag[tagOf[account]]`. Tags are demo codes (`keccak256("US-AI")`), not ISO countries, not geofences.

`forceTransfer` skips both knobs. A recovery that would exceed max-balance is allowed; that is god-mode, documented here and tested.

## Assets / conservation

1. `totalSupply` changes only in ISSUER `mint` / `burn`. Freeze and `forceTransfer` are conservation-preserving. Locked by unit tests, fuzz, and the invariant handler (`ghostMinted - ghostBurned`).
2. ERC-20 conservation still applies: `forceTransfer` reverts on insufficient balance; it cannot print.
3. `forceTransfer` rejects `from == 0` or `to == 0` so it cannot be smuggled into mint/burn.

## Out of scope / explicit non-goals

- Legal compliance, broker-dealer status, ERC-3643 / T-REX / ERC-1400 certification.
- KYC/KYB vendors, OFAC, accredited-investor checks, geofencing, privacy.
- Upgradeability, timelock, pause, snapshots, dividends, voting, fees.
- Oracles, NAV, underlying asset custody, off-chain cap tables.
- Formal verification, bug bounty, on-chain monitoring.
- Fee-on-transfer wrapping (this token *is* the permissioned asset, not a wrapper).

## Invariants (tested)

1. `totalSupply` unchanged by freeze or `forceTransfer`; only ISSUER mint/burn changes it.
2. Unverified address cannot receive or send except issuer mint and `forceTransfer`.
3. Frozen address cannot send or receive on the user path (mint/burn included). `forceTransfer` may still move frozen balances.
4. Only ISSUER mints.
5. Unauthorized freeze / `forceTransfer` / `setVerified` revert.

## What this is not

This is not a substitute for counsel, a transfer agent, an audit, or a KYC vendor. It is a portfolio-grade **restriction shape**: registry, freeze, recovery, compliance knobs, and tests a hiring manager can run with `forge test`.
