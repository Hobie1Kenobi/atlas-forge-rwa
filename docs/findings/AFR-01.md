# AFR-01 — Self-transfer overstated post-balance for `maxBalance`

- **ID:** AFR-01
- **Severity:** Low
- **Status:** Fixed in this PR
- **Component:** `PermissionedToken._checkPermissioned`

## Root cause

User `transfer` / `transferFrom` passed `balanceOf(to) + value` into
`Compliance.validateTransfer` even when `from == to`. A self-transfer does not
increase the recipient's balance (ERC-20 subtracts then adds the same account).

## Impact

A verified holder already at `maxBalance` could not `transfer` (or
`transferFrom`) to themselves. No funds moved incorrectly; the policy check was
wrong for a no-op path. Other recipients were computed correctly.

## PoC test name

`test_self_transfer_at_max_balance_does_not_revert`
(`test/Compliance.t.sol`)

Also: `test_self_transfer_from_still_at_max_balance`.

## Fix or accepted residual

**Fixed.** `_checkPermissioned` now uses `balanceOf(to)` when `from == to`, and
`balanceOf(to) + value` otherwise.

## Retest

```bash
forge test --match-test test_self_transfer_at_max_balance
```
