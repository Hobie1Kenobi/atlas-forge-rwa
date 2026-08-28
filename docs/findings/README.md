# Internal A5 security review — Atlas Forge RWA

**This is not a paid audit. This is not ERC-3643 certification. This is not legal,
securities, KYC, or AUM diligence.**

Scope is **this repository only** (`Hobie1Kenobi/atlas-forge-rwa`, `main` at the
parent of this PR, plus the fixes in this PR). `atlas-forge-vault` was not modified
and was not re-reviewed here.

Reviewer posture: defensive findings against the **stated** threat model
(`docs/threat-model.md`). Issuer freeze / mint / `forceTransfer` are product
capabilities, not hidden backdoors. No Critical or High issues were identified
on this code. No exploit payloads are included.

There is **no AUM**, **no deployment**, **no transfer agent**, and **no claim** that
`afpUSD` is dollars.

## Method

- Read `src/PermissionedToken.sol`, `IdentityRegistry.sol`, `Compliance.sol`,
  `script/Deploy.s.sol`, and the Foundry suites.
- Mapped every `transfer` / `transferFrom` / `mint` / `burn` / `forceTransfer` path
  through `_update` vs `ERC20._update`.
- Wrote or extended tests that **lock** both the three Low fixes and the accepted
  residuals. Tests are named after the behavior; they are not attack scripts.

## Summary

| ID | Severity | Status | Title |
| --- | --- | --- | --- |
| [AFR-01](AFR-01.md) | Low | **Fixed** | Self-transfer overstated post-balance for `maxBalance` |
| [AFR-02](AFR-02.md) | Low | **Fixed** | Deploy `grantRole` required the broadcaster to already be `DEFAULT_ADMIN` |
| [AFR-03](AFR-03.md) | Low | **Fixed** | `forceTransfer` used a storage flag that would skip nested user-path checks |
| [AFR-04](AFR-04.md) | Informational | Accepted residual | Issuer-is-god (mint, burn, freeze, recovery) |
| [AFR-05](AFR-05.md) | Informational | Accepted residual | ISSUER mint/burn skip the verified-registry check |
| [AFR-06](AFR-06.md) | Informational | Accepted residual | `forceTransfer` bypasses freeze, registry, cap, and tags |
| [AFR-07](AFR-07.md) | Informational | Accepted residual | v1 `DEFAULT_ADMIN` is a single EOA, not a timelock |
| [AFR-08](AFR-08.md) | Informational | Accepted residual | Default deploy name/symbol `afpUSD` is a label, not a USD claim |
| [AFR-09](AFR-09.md) | Informational | Accepted residual | `ISSUER_ROLE` is per-contract; token issuer ≠ registry issuer |
| [AFR-10](AFR-10.md) | Informational | Accepted residual | `transferFrom` gates `from`/`to`, not the spender |
| [AFR-11](AFR-11.md) | Informational | Accepted residual | `tagsEnforced` default-denies the zero tag |

No Medium / High / Critical. Inventing those would misrepresent this sketch.

## What was out of scope

- Legal compliance, broker-dealer status, ERC-3643 / T-REX / ERC-1400 certification.
- KYC/KYB vendors, OFAC, accredited-investor checks, geofencing, privacy.
- Underlying asset custody, NAV, oracles, cap tables, AUM.
- Upgradeability, 48h timelock (shown in atlas-forge-vault, not duplicated here).
- Formal verification, bug bounty, on-chain monitoring.

## Retest

```bash
git submodule update --init --recursive
forge test
```

Fixes: `test_self_transfer_at_max_balance_does_not_revert`,
`test_deploy_grants_roles_when_caller_is_not_admin`,
`test_accepted_force_transfer_bypasses_freeze_registry_cap_and_tags`.

Accepted design: `test/AcceptedDesign.t.sol`.
