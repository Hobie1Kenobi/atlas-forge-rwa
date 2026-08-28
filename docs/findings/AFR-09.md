# AFR-09 — `ISSUER_ROLE` is per-contract; token issuer ≠ registry issuer

- **ID:** AFR-09
- **Severity:** Informational
- **Status:** Accepted residual
- **Component:** `PermissionedToken`, `IdentityRegistry`, `Compliance`

## Root cause

Three `AccessControl` contracts each define `ISSUER_ROLE = keccak256("ISSUER_ROLE")`.
The identifiers match; the role **storage** does not. Granting ISSUER on the
token does not grant listing rights on the registry or knobs on compliance.

## Impact

An operator who is only token-ISSUER can mint/burn/`forceTransfer` but cannot
`setVerified` or `setMaxBalance`. An operator who is only registry-ISSUER can
list wallets but cannot mint. The deploy script grants the same `ISSUER` address
on all three; later `grantRole` calls can diverge.

## PoC test name

`test_accepted_token_issuer_is_not_automatically_registry_issuer`
(`test/AcceptedDesign.t.sol`)

## Fix or accepted residual

**Accepted.** Merging the three contracts (or a shared role module) would be a
larger redesign. Document the split; keep admin procedures in lockstep if a
fork goes live.

## Retest

```bash
forge test --match-test test_accepted_token_issuer_is_not_automatically_registry_issuer
```
