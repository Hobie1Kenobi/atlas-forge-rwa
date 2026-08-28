ATLAS FORGE RWA PUBLIC TESTNET ENGINEERING REHEARSAL.
This deployment does not represent a live security, investment product, USD-backed asset, audited protocol, KYC platform, or production issuance.

# Public testnet report

Fill on-chain sections only after a real Sepolia broadcast. This PR did **not**
broadcast. Where a field needs an explorer URL, tx hash, or live address, the
value is:

`NOT EXECUTED — no public-chain broadcast in this PR`

Token labeling for the public rehearsal: **Atlas Forge Permissioned Test Token**
/ **AFPT**. That is a label, not a USD peg, reserve, redeem, or AUM figure.

## Environment

| Field | Value |
| --- | --- |
| Repo | https://github.com/Hobie1Kenobi/atlas-forge-rwa |
| Branch | testnet-production-rehearsal |
| Base HEAD (start) | `0aabbf60c867959ba464343273d9cb761d00f33a` |
| Report commit | see `git rev-parse HEAD` on this branch after evidence commit |
| UTC timestamp | 2026-08-28T01:09:22Z (preflight start; local-CI timestamp in `artifacts/local-ci/environment.txt`) |
| OS | Linux cursor 6.12.94+ x86_64 |
| `forge --version` | forge 1.8.0 (61ae26af36 2026-08-26T13:14:38.112964122Z) |
| `cast --version` | cast 1.8.0 (61ae26af36 2026-08-26T13:14:38.112964122Z) |
| solc | 0.8.28 (`foundry.toml`) |
| evm_version | cancun |
| optimizer | true, 200 runs, via_ir false |

Raw command logs: `artifacts/local-ci/`.

## Local test suite / fuzz / invariant

Values below are copied from this agent's `forge` runs (terminal is authoritative).
Do not treat README's historical "~76 tests" as this revision's count.

| Command | Result |
| --- | --- |
| `forge clean` | see `artifacts/local-ci/01-forge-clean.txt` |
| `forge build --sizes` | see `artifacts/local-ci/02-forge-build-sizes.txt` |
| `forge test -vvv` | **PENDING_LOCAL_CI** |
| `forge coverage` | **PENDING_LOCAL_CI** |
| `forge test --gas-report` | **PENDING_LOCAL_CI** |
| `FOUNDRY_PROFILE=intense forge test -vvv` | **PENDING_LOCAL_CI** |

`[profile.intense.invariant] fail_on_revert = false` is **left unchanged**
(accepted residual: handlers catch expected reverts; the profile does not fail
the run on a reverted call).

## On-chain deployment

NOT EXECUTED — no public-chain broadcast in this PR

| Item | Value |
| --- | --- |
| IdentityRegistry | NOT EXECUTED — no public-chain broadcast in this PR |
| Compliance | NOT EXECUTED — no public-chain broadcast in this PR |
| PermissionedToken | NOT EXECUTED — no public-chain broadcast in this PR |
| Deploy tx | NOT EXECUTED — no public-chain broadcast in this PR |
| Explorer | NOT EXECUTED — no public-chain broadcast in this PR |

## On-chain smoke matrix

See `artifacts/sepolia/testnet-results.example.json`. Every `testName` from
`DEPLOY_REGISTRY` through `SUPPLY_LEDGER_MATCH` is **NOT EXECUTED**.

## Supply ledger / on-chain state

- `artifacts/supply-ledger.example.json` — empty entries
- `artifacts/onchain-state.example.json` — placeholder addresses

NOT EXECUTED — no public-chain broadcast in this PR

## Secret scan

First-party tree (`src/`, `script/`, `test/`, `docs/`, `.env.example`, CI): **no
private keys, mnemonics, API secrets, or live `.env` values**. Submodule
`lib/` contains well-known Foundry/OpenZeppelin test vectors (including Anvil's
public demo key) that are not secrets of this repo. `.gitignore` covers `.env`,
`.env.*` (with `!.env.example`), `*.pem`, `*.key`, `broadcast/`.

## Honesty

Not deployed. Not a product. Not an audit. Not ERC-3643 certified. Not KYC.
Not USD-backed.
