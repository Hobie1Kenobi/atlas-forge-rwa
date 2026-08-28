# AFR-03 — `forceTransfer` used a storage flag that would skip nested user-path checks

- **ID:** AFR-03
- **Severity:** Low
- **Status:** Fixed in this PR
- **Component:** `PermissionedToken.forceTransfer` / `_update`

## Root cause

`forceTransfer` set `_inForcedTransfer = true`, called the overridden `_update`
(which skipped `_checkPermissioned`), then cleared the flag. ERC-20 v5 `_update`
has no token callbacks, so there is no current reentrancy. The flag was still a
global bypass: any nested `transfer` / `mint` / `burn` during that window would
have skipped identity, freeze, and compliance.

## Impact

No current callback surface, so no funds at risk on this revision. The pattern
is a footgun if a future fork adds hooks (ERC-777-style receivers, external
calls from a child `_update`). Using a storage bool also spent extra SSTORE gas
for a check that `super._update` already avoids.

## PoC test name

`test_accepted_force_transfer_bypasses_freeze_registry_cap_and_tags`
(`test/AcceptedDesign.t.sol`)

Existing recovery tests still lock that user `transfer` never gets the bypass.

## Fix or accepted residual

**Fixed.** `forceTransfer` calls `ERC20._update` via `super._update` and does not
set a flag. Permissioned `_update` always runs `_checkPermissioned`. The
recovery bypass remains **intentional** (see AFR-06); only the implementation
changed.

## Retest

```bash
forge test --match-test test_force_transfer
forge test --match-test test_accepted_force_transfer
```
