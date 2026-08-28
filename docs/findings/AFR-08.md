# AFR-08 — Default deploy name/symbol is a label, not a USD claim

- **ID:** AFR-08
- **Severity:** Informational
- **Status:** Accepted residual (hygiene: ticker no longer looks like a dollar)
- **Component:** `script/Deploy.s.sol`, fixture, `.env.example`

## Root cause

The rehearsal script used to default `TOKEN_NAME` to `Atlas Forge Permissioned USD`
and `TOKEN_SYMBOL` to `afpUSD`. That ticker is a **mistake-class risk**: it looks
like a dollar claim. There is no reserve, oracle, redeem-to-USD, or custody
contract in this repo.

`Deploy.s.sol` `envOr` fallbacks are now `Atlas Forge Permissioned Test Token` /
`AFPT`, matching `.env.example` and the deployed Sepolia token. AFPT is still
only a label. 18 decimals are the OpenZeppelin ERC-20 default.

## Impact

A hurried reader could treat a USD-looking ticker as a stablecoin or as AUM.
Changing the fallback to AFPT removes that overclaim. It does **not** add
reserves. Running `forge script` still does not create a dollar, a security, or
a live issuance.

## PoC test name

`test_accepted_deploy_name_AFPT_is_label_not_usd_claim`
(`test/AcceptedDesign.t.sol`)

Also: `test_deploy_default_labels_match_env_example`.

## Fix or accepted residual

**Partial hygiene + accepted residual.** The `afpUSD` fallback was retired
because it looks like a dollar claim. The residual is honesty: `AFPT` / `Atlas
Forge Permissioned Test Token` are labels, not a USD peg, reserve, redeem, or
AUM figure.

## Retest

```bash
forge test --match-test test_accepted_deploy_name_AFPT
```
