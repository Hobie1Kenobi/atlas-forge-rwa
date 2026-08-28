# AFR-10 — `transferFrom` gates `from`/`to`, not the spender

- **ID:** AFR-10
- **Severity:** Informational
- **Status:** Accepted residual
- **Component:** `PermissionedToken._checkPermissioned`

## Root cause

The user path checks that `from` and `to` are verified and not frozen. It does
not check `msg.sender`. An unverified spender with allowance can move tokens
between two verified, unfrozen holders. `approve` is similarly ungated.

This matches common ERC-20 operator semantics (and T-REX `transferFrom`, which
also checks the two parties, not the spender).

## Impact

A listed holder who approves an unlisted router or EOA lets that operator move
their tokens to another listed address. The operator cannot send or receive on
their own account without being listed (or without issuer mint / `forceTransfer`).

## PoC test name

`test_accepted_unverified_spender_may_transferFrom_between_verified`
(`test/AcceptedDesign.t.sol`)

## Fix or accepted residual

**Accepted.** Requiring the spender to be verified would block unlabeled
contracts (routers, settlement adapters) unless the issuer listed them. v1 gates
holders, not operators. A fork that wants “only verified callers” should add
that check explicitly.

## Retest

```bash
forge test --match-test test_accepted_unverified_spender
```
