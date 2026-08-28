# Preflight review — Atlas Forge RWA public testnet rehearsal

**ATLAS FORGE RWA PUBLIC TESTNET ENGINEERING REHEARSAL.**
This is not a live security, investment product, USD-backed asset, audited
protocol, KYC platform, or production issuance.

Started from `main` at `0aabbf60c867959ba464343273d9cb761d00f33a`.
Branch: `testnet-production-rehearsal`.
Repo: https://github.com/Hobie1Kenobi/atlas-forge-rwa

Environment snapshot (also `artifacts/local-ci/environment.txt`):

| Field | Value |
| --- | --- |
| UTC (preflight start) | 2026-08-28T01:09:22Z |
| OS | Linux 6.12.94+ x86_64 |
| forge | 1.8.0 (61ae26af36320d4fa1020f7db53785885e29eeb5) |
| cast | 1.8.0 (61ae26af36320d4fa1020f7db53785885e29eeb5) |
| solc | 0.8.28 |
| evm_version | cancun (`foundry.toml`) |

`git submodule update --init --recursive` completed:
`lib/forge-std` @ `77041d2ce690e692d6e03cc812b57d1ddaa4d505` (v1.9.7),
`lib/openzeppelin-contracts` @ `c64a1edb67b6e3f4a15cca8909c9482ad33a02b0` (v5.4.0).

## Secret scan

Scanned first-party paths. **No live private keys, mnemonics, API keys, or
keystore files.** `.env.example` holds empty placeholders only. `broadcast/` is
gitignored. Submodule fixtures include well-known public test keys (Anvil
demo); those are not this project's secrets.

If a real secret had been found in git, this rehearsal would have stopped.

## Trust model (issuer-is-god — not a vulnerability)

Documented roles are the product:

| Role | Contract | Power |
| --- | --- | --- |
| `DEFAULT_ADMIN_ROLE` | all three | `grantRole` / `revokeRole`. v1 is a single address (AFR-07). |
| `ISSUER_ROLE` | `PermissionedToken` | `mint`, `burn`, `forceTransfer` |
| `ISSUER_ROLE` | `IdentityRegistry` | `setVerified` (independent storage, AFR-09) |
| `ISSUER_ROLE` | `Compliance` | `setMaxBalance`, tags (independent storage, AFR-09) |
| `FREEZER_ROLE` | `PermissionedToken` | `freeze` / `unfreeze` (no balance movement) |
| `RECOVERY_ROLE` | `PermissionedToken` | `forceTransfer` (with ISSUER) |

A compromised ISSUER can inflate supply and force-move any balance. A
compromised FREEZER can trap user transfers (recovery still works). A
compromised RECOVERY can seize tokens onto any address. That is permissioned
RWA. Do not ship with an untrusted EOA. Do not relabel this as a hidden backdoor.

## Mint / burn / freeze / forceTransfer authority

- **Mint** (`onlyRole(ISSUER_ROLE)`): supply up. Skips verified-registry on
  `to`. Reverts if `to` frozen. Max-balance and tags still apply. Zero amount
  reverts `ZeroAmount`.
- **Burn** (`onlyRole(ISSUER_ROLE)`): supply down. Skips verified-registry on
  `from`. Reverts if `from` frozen (unfreeze, then burn).
- **Freeze / unfreeze** (`onlyRole(FREEZER_ROLE)`): flags only. Supply constant.
- **forceTransfer** (RECOVERY or ISSUER): calls `ERC20._update` via `super`, so
  it **bypasses** verified, freeze, max-balance, and tags. Rejects `from`/`to`
  zero (`ForceTransferMintOrBurn`). Does not mint or burn. Does not spend
  allowance. Replacement wallet may be unverified — documented recovery.

Unauthorized mint/freeze/setVerified/forceTransfer revert. Those reverts are
PASS in the smoke matrix.

## Registry / compliance bypasses (accepted)

| Path | Verified | Freeze | maxBalance / tags |
| --- | --- | --- | --- |
| User `transfer` / `transferFrom` | required both sides | required both sides | required (self-transfer does not add `value`) |
| ISSUER `mint` | skipped on `to` | `to` must not be frozen | still applied |
| ISSUER `burn` | skipped on `from` | `from` must not be frozen | n/a (burn) |
| `forceTransfer` | skipped | skipped | skipped |

`transferFrom` gates `from`/`to`, not the spender (AFR-10). An unverified
spender with allowance can move tokens between two listed, unfrozen holders.

## Supply-changing vs supply-preserving

**Supply-changing:** ISSUER `mint`, ISSUER `burn` only.

**Supply-preserving:** freeze, unfreeze, `forceTransfer`, `setVerified`,
compliance knobs, user transfers (conservation of `totalSupply`).

Locked by unit tests, fuzz (`testFuzz_forceTransferPreservesSupply`), and
`invariant_supplyMatchesMintBurn` (`ghostMinted - ghostBurned`).

## Deployment assumptions / constructor dependencies

Order: `IdentityRegistry(admin, issuer)` then `Compliance(admin, issuer)` then
`PermissionedToken(name, symbol, admin, issuer, freezer, recovery, registry, compliance)`.

- `admin`, `registry`, `compliance` cannot be zero on the token.
- `issuer` / `freezer` / `recovery` may be zero (role left unassigned until
  `grantRole`).
- Constructors grant roles; the broadcaster need not equal `ADMIN` (AFR-02).
- `Deploy.s.sol` `envOr` falls back to `msg.sender` for missing role envs —
  overlap is easy. Public rehearsal must set explicit addresses or acknowledge
  `ACK_ROLE_OVERLAP=true`.
- Solidity fallback name/symbol remain `Atlas Forge Permissioned USD` /
  `afpUSD` because tests lock those strings (AFR-08). **Documented testnet
  path** uses env `TOKEN_NAME="Atlas Forge Permissioned Test Token"` /
  `TOKEN_SYMBOL=AFPT`. Neither is a USD claim.
- Registry and compliance addresses are `immutable` on the token. No setters.
  Swapping policy means a new token.

No proxy, no pause, no timelock in this repo.

## Accepted residual risks (not scored as vulns)

From `docs/findings/` plus this rehearsal:

- AFR-01, AFR-02, AFR-03: **Fixed** on `main` (self-transfer cap, constructor
  role grant, `forceTransfer` via `super._update`).
- AFR-04 issuer-is-god
- AFR-05 mint/burn skip registry
- AFR-06 forceTransfer bypass
- AFR-07 EOA admin
- AFR-08 default sketch ticker is a label
- AFR-09 per-contract ISSUER
- AFR-10 spender not gated
- AFR-11 zero tag denied when tags enforced
- Intense invariant profile `fail_on_revert = false` (unchanged)
- Identity is a list, not KYC
- Tags are demo/test policy codes, not sanctions
- No mainnet controls listed in `docs/production-gap-analysis.md`

## `src/` changes in this PR

**None intended.** Rehearsal adds scripts, tests for tooling, docs, and
evidence templates only.

## Local CI

See `artifacts/local-ci/` and `PUBLIC_TESTNET_REPORT.md`. Counts are taken from
the terminal, not from README hypothesis (~76 on a prior revision).
