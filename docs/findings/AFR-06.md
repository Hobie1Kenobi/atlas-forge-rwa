# AFR-06 — `forceTransfer` bypasses freeze, registry, cap, and tags

- **ID:** AFR-06
- **Severity:** Informational
- **Status:** Accepted residual
- **Component:** `PermissionedToken.forceTransfer`

## Root cause

Lost-key / court-order recovery must move frozen or unverified balances onto a
replacement wallet, including when that would exceed `maxBalance` or when tags
are enforced. `forceTransfer` therefore calls `ERC20._update` directly. It still
cannot mint or burn (`from`/`to` cannot be zero) and still reverts on
insufficient balance. It does **not** spend ERC-20 allowance.

## Impact

RECOVERY or ISSUER can place tokens on any address, including frozen and
unverified. `totalSupply` is unchanged. User `transfer` never gets this bypass.

## PoC test name

`test_accepted_force_transfer_bypasses_freeze_registry_cap_and_tags`
(`test/AcceptedDesign.t.sol`)

Also: `test_force_transfer_bypasses_max_balance`,
`test_force_transfer_bypasses_tags`,
`test_accepted_force_transfer_does_not_spend_allowance`,
`test_force_transfer_cannot_mint_or_burn`.

## Fix or accepted residual

**Accepted.** Removing the bypass would make freeze a hard lock even against the
issuer, which is not this design. Document the bypass to integrators; do not
treat it as an exploit.

## Retest

```bash
forge test --match-test test_accepted_force_transfer
forge test --match-test test_force_transfer_bypasses
```
