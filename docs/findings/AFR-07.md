# AFR-07 — v1 `DEFAULT_ADMIN` is a single EOA, not a timelock

- **ID:** AFR-07
- **Severity:** Informational
- **Status:** Accepted residual
- **Component:** constructors / AccessControl

## Root cause

v1 grants `DEFAULT_ADMIN_ROLE` to one address. That address can `grantRole` /
`revokeRole` for ISSUER, FREEZER, and RECOVERY (and can grant itself those
roles). There is no 48h delay, no `AccessControlDefaultAdminRules`, and no
on-chain two-step admin transfer.

atlas-forge-vault already demonstrates a 48h `TimelockController` as
`DEFAULT_ADMIN`. This repo does not duplicate that pattern.

## Impact

Compromise of the admin key is compromise of every role. Holders have no delay
window. OpenZeppelin documents this class of risk on `AccessControl`.

This is **not** scored High: the threat model states it, tests lock that admin
cannot mint without ISSUER, and the sketch is not deployed.

## PoC test name

`test_accepted_default_admin_is_single_address_not_timelock`
(`test/AcceptedDesign.t.sol`)

Also: `test_only_issuer_mints` (admin without ISSUER reverts).

## Fix or accepted residual

**Accepted** for v1. A production fork should put `DEFAULT_ADMIN` on a timelock
(or equivalent) and split operational keys. Do not treat an EOA admin as a
production control.

## Retest

```bash
forge test --match-test test_accepted_default_admin
```
