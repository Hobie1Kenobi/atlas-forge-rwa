# AFR-05 — ISSUER mint/burn skip the verified-registry check

- **ID:** AFR-05
- **Severity:** Informational
- **Status:** Accepted residual
- **Component:** `PermissionedToken._checkPermissioned`

## Root cause

Mint and burn skip `registry.isVerified` so the issuer can seed or unwind a
wallet before or after listing. Freeze and compliance (max-balance, tags) still
apply on mint; freeze still applies on burn.

## Impact

Tokens can sit on an unverified address after mint. That address cannot
`transfer` them out on the user path until listed (or until `forceTransfer` /
issuer `burn`). Integrators must not assume `balanceOf > 0` implies verified.

## PoC test name

`test_accepted_mint_to_unverified`
(`test/AcceptedDesign.t.sol`)

Also: `test_issuer_mint_to_unverified_succeeds`,
`test_issuer_burn_from_unverified_succeeds`.

## Fix or accepted residual

**Accepted.** Requiring verification on mint would block the documented seed
flow. User `transfer` / `transferFrom` still revert for unverified `from`/`to`.

## Retest

```bash
forge test --match-test test_accepted_mint_to_unverified
```
