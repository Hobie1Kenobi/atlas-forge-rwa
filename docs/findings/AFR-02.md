# AFR-02 — Deploy `grantRole` required the broadcaster to already be `DEFAULT_ADMIN`

- **ID:** AFR-02
- **Severity:** Low
- **Status:** Fixed in this PR
- **Component:** `script/Deploy.s.sol`, constructors

## Root cause

Constructors granted `DEFAULT_ADMIN_ROLE` to the `admin` argument, then the
script called `grantRole` for ISSUER / FREEZER / RECOVERY. Those calls succeed
only if `msg.sender` is already `DEFAULT_ADMIN`. Under `forge script`, the
broadcaster is the sender of `grantRole`. If `ADMIN` was a different address
than the broadcasting key, role grants reverted. The same failure happens if a
helper contract deploys on behalf of `admin`.

## Impact

Local/testnet rehearsal could not finish unless `ADMIN` equaled the broadcaster.
The repo is **not deployed**; this did not affect a live issuance. Simulation
typically fails closed (no half-granted broadcast) rather than leaving an
un-issuing token on-chain.

## PoC test name

`test_deploy_grants_roles_when_caller_is_not_admin`
(`test/AcceptedDesign.t.sol`)

Also: `test_constructor_grants_issuer_without_deployer_admin`.

## Fix or accepted residual

**Fixed.** Constructors grant `DEFAULT_ADMIN` and the operational roles from the
constructor arguments. The script no longer calls `grantRole`. The deploying
contract does not need to be admin.

## Retest

```bash
forge test --match-test test_deploy_grants_roles_when_caller_is_not_admin
```
