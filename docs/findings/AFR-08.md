# AFR-08 — Default deploy name/symbol `afpUSD` is a label, not a USD claim

- **ID:** AFR-08
- **Severity:** Informational
- **Status:** Accepted residual
- **Component:** `script/Deploy.s.sol`, fixture, `.env.example`

## Root cause

The rehearsal script defaults `TOKEN_NAME` to `Atlas Forge Permissioned USD` and
`TOKEN_SYMBOL` to `afpUSD`, with 18 decimals (OpenZeppelin ERC-20 default). There
is no reserve, oracle, redeem-to-USD, or custody contract in this repo.

## Impact

A hurried reader could treat the ticker as a stablecoin or as AUM. It is a
**label** for a permissioned ERC-20 sketch. Running `forge script` does not
create a dollar, a security, or a live issuance.

## PoC test name

`test_accepted_deploy_name_afpUSD_is_label_not_usd_claim`
(`test/AcceptedDesign.t.sol`)

Also: `test_deploy_default_labels_match_env_example`.

## Fix or accepted residual

**Accepted.** The default string is kept so tests and `.env.example` stay
honest about what the sketch currently prints. Docs and the deploy log state
that the name is not a USD claim. Changing the ticker would not add reserves;
it would only hide the overclaim instead of labeling it.

## Retest

```bash
forge test --match-test test_accepted_deploy_name_afpUSD
```
