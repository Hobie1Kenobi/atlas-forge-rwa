# Scripts — public testnet rehearsal (no keys in git)

This directory is **engineering rehearsal tooling**. It is not a live issuance,
not a USD-backed token, not KYC, and not an audit.

**This PR does not broadcast.** Do not run `--broadcast` until dedicated Sepolia
addresses exist and you intend to send real transactions. `broadcast/` is
gitignored because Foundry `run-latest.json` can contain private keys. Evidence
JSON must be hand-written sanitized records, never a copy of broadcast JSON.

Sign with a Foundry keystore. Foundry 1.8.0 supports `--account <name>` (reads
`~/.foundry/keystores/<name>`). Do **not** use `--private-key`.

Create the keystore once on your machine (not in CI, not in this repo):

```bash
cast wallet import atlas-deployer --interactive
```

Chain id **must** be `11155111` (Sepolia). `TestnetSmoke` reverts `WrongChain` otherwise.

## Environment

Copy `.env.example` to a local `.env` (gitignored). Fill addresses after deploy.
Public rehearsal labels:

```bash
TOKEN_NAME="Atlas Forge Permissioned Test Token"
TOKEN_SYMBOL=AFPT
```

`Deploy.s.sol` Solidity `envOr` fallbacks remain the older sketch labels so unit
tests that lock those strings stay honest. The documented testnet path is AFPT
via env.

If faucet limits force one keystore to hold ADMIN/ISSUER/FREEZER/RECOVERY:

```bash
ACK_ROLE_OVERLAP=true
```

The smoke script logs that as a limitation. `ALICE`, `BOB`, and `CHARLIE` must
still be distinct. `UNAUTHORIZED` must not hold privileged roles.

## Deploy (Sepolia only, not executed in this PR)

```bash
set -a && source .env && set +a
forge script script/Deploy.s.sol:Deploy \
  --rpc-url "$SEPOLIA_RPC_URL" \
  --account atlas-deployer \
  --broadcast
```

Optional verify (placeholder API key in `.env.example`, never commit a real key):

```bash
forge script script/Deploy.s.sol:Deploy \
  --rpc-url "$SEPOLIA_RPC_URL" \
  --account atlas-deployer \
  --broadcast \
  --verify \
  --etherscan-api-key "$ETHERSCAN_API_KEY"
```

Record constructor addresses by hand into `deployments/sepolia.json` (not
committed with live secrets; see `deployments/sepolia.example.json`).

## Smoke — view preflight (no broadcast)

Requires live `TOKEN`, `REGISTRY`, `COMPLIANCE` addresses with code on Sepolia.

```bash
set -a && source .env && set +a
forge script script/TestnetSmoke.s.sol:TestnetSmoke \
  --sig "preflight()" \
  --rpc-url "$SEPOLIA_RPC_URL"
```

## Smoke — full matrix (broadcast later; staged by signer)

Default `run()` executes every step the keystore can sign and logs `STAGE:` for
the rest. Reverts on unauthorized mint/freeze/setVerified/forceTransfer/burn are
**PASS**.

```bash
set -a && source .env && set +a
forge script script/TestnetSmoke.s.sol:TestnetSmoke \
  --rpc-url "$SEPOLIA_RPC_URL" \
  --account atlas-deployer \
  --broadcast
```

If holders use dedicated keystores, re-run the staged functions with the matching
account (Foundry `--account` flag, same as above):

```bash
forge script script/TestnetSmoke.s.sol:TestnetSmoke --sig "stepSetVerified()" \
  --rpc-url "$SEPOLIA_RPC_URL" --account atlas-deployer --broadcast

forge script script/TestnetSmoke.s.sol:TestnetSmoke --sig "stepMint()" \
  --rpc-url "$SEPOLIA_RPC_URL" --account atlas-deployer --broadcast

forge script script/TestnetSmoke.s.sol:TestnetSmoke --sig "stepAliceToBob()" \
  --rpc-url "$SEPOLIA_RPC_URL" --account atlas-alice --broadcast

forge script script/TestnetSmoke.s.sol:TestnetSmoke --sig "stepUnverifiedTransfers()" \
  --rpc-url "$SEPOLIA_RPC_URL" --account atlas-alice --broadcast

forge script script/TestnetSmoke.s.sol:TestnetSmoke --sig "stepUnauthorizedReverts()" \
  --rpc-url "$SEPOLIA_RPC_URL" --account atlas-unauthorized --broadcast

forge script script/TestnetSmoke.s.sol:TestnetSmoke --sig "stepFreeze()" \
  --rpc-url "$SEPOLIA_RPC_URL" --account atlas-deployer --broadcast

forge script script/TestnetSmoke.s.sol:TestnetSmoke --sig "stepFrozenTransfers()" \
  --rpc-url "$SEPOLIA_RPC_URL" --account atlas-alice --broadcast

forge script script/TestnetSmoke.s.sol:TestnetSmoke --sig "stepUnfreeze()" \
  --rpc-url "$SEPOLIA_RPC_URL" --account atlas-deployer --broadcast

forge script script/TestnetSmoke.s.sol:TestnetSmoke --sig "stepForceTransfer()" \
  --rpc-url "$SEPOLIA_RPC_URL" --account atlas-deployer --broadcast

forge script script/TestnetSmoke.s.sol:TestnetSmoke --sig "stepCompliance()" \
  --rpc-url "$SEPOLIA_RPC_URL" --account atlas-deployer --broadcast

forge script script/TestnetSmoke.s.sol:TestnetSmoke --sig "stepBurn()" \
  --rpc-url "$SEPOLIA_RPC_URL" --account atlas-deployer --broadcast
```

Attestation hashes are `keccak256("ATLAS_TEST_ATTESTATION_ALICE_V1")` (and BOB).
Never put PII on-chain.

## What this script will not do

- Will not run on Anvil/local (`WrongChain` unless `11155111`)
- Will not read Foundry `broadcast/` JSON into evidence files
- Will not treat DEFAULT_ADMIN / ISSUER / FREEZER / RECOVERY as vulnerabilities
