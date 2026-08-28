# AFR-04 — Issuer-is-god (mint, burn, freeze, recovery)

- **ID:** AFR-04
- **Severity:** Informational
- **Status:** Accepted residual
- **Component:** `PermissionedToken` roles

## Root cause

A permissioned RWA token gives the issuer supply control, a freezer the ability
to halt user movement, and recovery the ability to reassign balances. That is
the product, documented in `README.md` and `docs/threat-model.md`.

## Impact

A compromised ISSUER can inflate supply and `forceTransfer` any balance. A
compromised FREEZER can trap user transfers until unfrozen (recovery still
works). A compromised RECOVERY can seize tokens onto any address. Users have no
on-chain exit against those roles.

This is **not** a hidden backdoor and is **not** scored High.

## PoC test name

`test_accepted_issuer_is_god_mint_burn_freeze_force`
(`test/AcceptedDesign.t.sol`)

## Fix or accepted residual

**Accepted.** Do not ship with an untrusted EOA on these roles. A production
fork should split keys and put `DEFAULT_ADMIN` on a timelock (AFR-07). This
sketch will not pretend those roles are unprivileged.

## Retest

```bash
forge test --match-test test_accepted_issuer_is_god
```
