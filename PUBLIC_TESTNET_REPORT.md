ATLAS FORGE RWA PUBLIC TESTNET ENGINEERING REHEARSAL.
This deployment does not represent a live security, investment product, USD-backed asset, audited protocol, KYC platform, or production issuance.

# Public testnet report

Ethereum Sepolia (chainId `11155111`) engineering rehearsal of AFPT. This is
**not** a live issuance, **not** USD-backed, **not** an audit, **not** ERC-3643,
and **not** KYC. Token name/symbol on-chain: **Atlas Forge Permissioned Test
Token** / **AFPT**. That is a label, not a USD peg, reserve, redeem, or AUM
figure.

`src/` was **not** modified. Evidence JSON is hand-written and sanitized. Foundry
`broadcast/` / `run-latest` JSON was **not** committed (it can contain secrets).
Foundry `contractName` in broadcast JSON was misaligned; contract identities
below trust on-chain receipts and Sourcify exact-match pages.

## Release gate (honest)

| Gate | Result |
| --- | --- |
| PUBLIC TESTNET BEHAVIORAL MATRIX | **PASS** |
| SOURCIFY | **PASS** (all three `exact_match`) |
| ETHERSCAN | **FAIL** (Sourcify-to-Etherscan relay hit daily 500 submission cap). Do not mark Etherscan verified. |
| EVIDENCE PACKAGE | this PR |
| OVERALL | **TESTNET REHEARSAL INCOMPLETE** until Etherscan verification succeeds **OR** the operator accepts Sourcify-only. This report does **not** manufacture a full PASS. |
| Base Sepolia | **NOT EXECUTED** |

Not production ready. Not audited. Not a compliant RWA product.

## Environment

| Field | Value |
| --- | --- |
| Repo | https://github.com/Hobie1Kenobi/atlas-forge-rwa |
| Branch | `testnet-sepolia-evidence` |
| Git commit deployed from | `0807cdab8acb6769eaf67c39cc6b7ad5b2e9770f` (deploy bytecode) |
| Evidence package commit | `a82508147da003a5ab98e40f7455812cc5cd2aa6` (public testnet report on `main`) |
| Network | Ethereum Sepolia |
| chainId | 11155111 |
| Deployed at (UTC) | 2026-08-28T01:26:50Z approximately (block 11581611) |
| Local / operator date | 2026-08-27 CT / 2026-08-28 UTC |
| Final RPC snapshot | block ~11581660 |
| `forge --version` | Foundry 1.8.0 |
| solc | 0.8.28 |
| evm_version | cancun |
| optimizer | true, 200 runs |

Local CI (already on `main`, `src/` unchanged): `forge test` **78 passed**;
`FOUNDRY_PROFILE=intense` **78 passed** (fuzz 5000, invariant 256 runs / 12800
calls / 0 reverts). Raw logs: `artifacts/local-ci/`.

## Role overlap (disclosed)

| Role | Address |
| --- | --- |
| ADMIN = ISSUER = FREEZER = RECOVERY | `0xB2636381c7a501DfB316ea786a2c689324318b01` |
| ALICE | `0x24A70d01E3440A8B291a0eAE148ADab6640779B1` |
| BOB | `0x6BA6855b0C35A556A334326B5D8Eb494830e0dE5` |
| CHARLIE = UNAUTHORIZED | `0xadD8E3672B6EFBA5eEa6a317e144D5D4F8E07813` |

`ACK_ROLE_OVERLAP=true`. Faucet limitation, **not** production IAM. Documented
roles remain issuer-is-god (AFR-04 through AFR-07), not hidden vulnerabilities.

## On-chain deployment

| Contract | Address | Bytecode | Deploy tx | Block | gasUsed | Sourcify | Etherscan |
| --- | --- | --- | --- | --- | --- | --- | --- |
| IdentityRegistry | `0x57B7434E34702fFEA2825D6F23B651c20207E814` | 1535 bytes | `0x0b0dc5791e85870d925a324e81bb358d5279c9669065523c18cfe853ba0c130e` | 11581611 | 441695 | [exact_match](https://repo.sourcify.dev/11155111/0x57B7434E34702fFEA2825D6F23B651c20207E814) | **NOT verified** (daily cap) |
| Compliance | `0xB050a43e5Dd7dF0Ad626cAF9f179549bF4deFD12` | 2285 bytes | `0xaa85254e2cb02a4a5c9b7f41063993ed0c8e2bd117f26fe76d0f17c38b5690fe` | 11581611 | 604023 | [exact_match](https://repo.sourcify.dev/11155111/0xB050a43e5Dd7dF0Ad626cAF9f179549bF4deFD12) | **NOT verified** (daily cap) |
| PermissionedToken | `0x1FF6c5A4890C9F3ef499732fC82Fc270E1EA6759` | 4872 bytes | `0x714b930896440a17d429c0cb6964ef58ee96f7869b2436c8f31a52b6f6edd18c` | 11581611 | 1319019 | [exact_match](https://repo.sourcify.dev/11155111/0x1FF6c5A4890C9F3ef499732fC82Fc270E1EA6759) | **NOT verified** (daily cap) |

On-chain `name()` / `symbol()`: **Atlas Forge Permissioned Test Token** / **AFPT**.
`registry()` and `compliance()` on the token match the two addresses above.

Sanitized record: `deployments/sepolia.json`.

## Behavioral matrix

Expected user-path reverts were submitted as real txs with **status 0**. Those
failures are **positive evidence** (PASS). Full table:
`artifacts/sepolia/testnet-results.json`.

### Successful txs (status 1)

| Operator name | Required testName | Tx |
| --- | --- | --- |
| VERIFY_ALICE | IDENTITY_SET_VERIFIED_ALICE | `0xee29da64bbf05a1028ab76e042c6d63f5bddc797952f7f4c74781e10182c3e7d` |
| VERIFY_BOB | IDENTITY_SET_VERIFIED_BOB | `0x520535c82066d82d2bd0f5a15fb47372751113e0a40d464c263db31a0ade284d` |
| MINT_SUCCESS | MINT_ALICE_1000 / MINT_SUPPLY_DELTA | `0xd80ecc09b0ed193918fb0004629106adecf734990ff48dffba2a16d8abad9c80` (1000e18 to ALICE) |
| TRANSFER_VERIFIED_SUCCESS | TRANSFER_VERIFIED_ALICE_BOB_100 / TRANSFER_SUPPLY_CONSTANT | `0x1669a934d6e8b5e01cff23bc02daabf57e7d0d260943c5e265f1687517099388` (100e18 ALICE→BOB) |
| FREEZE_SUCCESS | FREEZE_ALICE | `0x4f0a6384c0fc2a9b2e3aa49fcef49f457fca8bbbe3f3da9294dcd47dcadd89de` |
| UNFREEZE_SUCCESS | UNFREEZE_ALICE | `0x2f8941ef06468ba6ccfa483e6c967f91278f1d5e5a9839c751cee0e02e6903b3` |
| TRANSFER_AFTER_UNFREEZE | TRANSFER_AFTER_UNFREEZE | `0x5815b98d00fc59c1541a106cee687af314edfb2c9859549d23e3d114cfbef271` (another 100e18 ALICE→BOB) |
| FREEZE_BEFORE_RECOVERY | (related to FORCE_TRANSFER) | `0xcd489bfd3ab621544b49baccd66fd5774182cf238e018e44ce537d82ca604ffd` |
| FORCE_TRANSFER_SUCCESS | FORCE_TRANSFER_FROZEN_ALICE_TO_REPLACEMENT / FORCE_TRANSFER_SUPPLY_CONSTANT | `0x7b3a264388562fa08c82cbc4c995b126b5a5794a9c5aa478ce8a8b6b305b9ae1` (ALICE 800e18 → CHARLIE/unverified replacement; supply unchanged) |
| MAX_BALANCE_SET | (related to COMPLIANCE_MAX_BALANCE_*) | `0xe0e6618b163e7e61c07d7c4833f5fd363550c1735a586646efc343c0b49deaa2` |
| MAX_BALANCE_PASS | COMPLIANCE_MAX_BALANCE_BELOW_CAP | `0x178d8b4b260e9e1f5ba193d5f5803cd94e13593395d616ba575af548041ff793` (1e18 to CHARLIE) |
| CLEAR_MAX | (related) | `0xabfe4aca5f534fd22502467bb6afb5f5459ca822afbf8276e5ebda82a9abd865` |
| TAG_ALLOW | TAG_ALLOWLIST_TEST_POLICY | `0xf29a2513e55c4f250b9292a80b99d0e855f4c44b5348885a95d4142f2300fbfd` |
| SET_BOB_TAG | TAG_ALLOWLIST_TEST_POLICY | `0x058a8fd2f612864050f23baf641ae4426acceffb8ea0c3495f90237728a1438d` |
| TAGS_ON | TAG_ALLOWLIST_TEST_POLICY | `0x14a75239502f6a60d51b62bea2e3056c5f08fdb0c34efdd6bdc19665811ace92` |
| TAG_ALLOW_PASS | TAG_ALLOWLIST_TEST_POLICY | `0xb89ce0e8180268d4404dda06d0747902ee810ff0e08a52ad452009e8342914d7` (mint bob) |
| TAGS_OFF | TAG_ALLOWLIST_TEST_POLICY | `0x9ec8da044ee7ecc1d54db8cc8cc2655da471d2306c15b836758691a3ac2be063` |
| BURN_SUCCESS | ISSUER_BURN | `0x6050c1e768282cf2101e48ca12c4846f53fb86b623b3d32545e6fa893c27dec8` (1e18 from BOB) |

### Failed txs (status 0, positive evidence)

| Operator name | Required testName | Tx |
| --- | --- | --- |
| UNAUTHORIZED_MINT_FAIL | UNAUTHORIZED_MINT_REVERT | `0xd549f700e2c34cf41f324e1a76b13dc18586d734867b147d2c8d4706c141eddc` |
| UNAUTHORIZED_FREEZE_FAIL | UNAUTHORIZED_FREEZE_REVERT | `0xbb8187f9b761db84c7c95c798fcdf10354202adfca35fd0ebf0e9db8d457259a` |
| UNAUTHORIZED_SET_VERIFIED_FAIL | UNAUTHORIZED_SET_VERIFIED_REVERT | `0xd43cfa1f91a23ee7984a8f934f51033c688b2faf257d1f24001fe9020f847eed` |
| UNAUTHORIZED_FORCE_TRANSFER_FAIL | UNAUTHORIZED_FORCE_TRANSFER_REVERT | `0x6aa426ec83883c29d1e7b0c9c7ae15bc8539e6a04ed9816a0a02b61216711ef3` |
| UNAUTHORIZED_BURN_FAIL | UNAUTHORIZED_BURN_REVERT | `0x41dbe3c99ed669a2b45ce58c653f72a2217faf71d61a0213d7124f9e7b1fea08` |
| UNAUTHORIZED_UNFREEZE_FAIL | UNAUTHORIZED_UNFREEZE_REVERT | `0xfac87c8019bc836738dc28f4361befc0fc5c5d45cb1fc93a6dd469bbf7594adf` |
| TRANSFER_UNVERIFIED_FAIL ALICE→CHARLIE | TRANSFER_UNVERIFIED_ALICE_CHARLIE_REVERT | `0xbb7c759bf93f96d4d548866fceafc7262d8c6965794fdc6ba4925cbaa82ff730` |
| TRANSFER_UNVERIFIED_FAIL CHARLIE→ALICE | TRANSFER_UNVERIFIED_CHARLIE_ALICE_REVERT | `0x17fcd15a55fff10e277ac5116c5f202425dcd11a895569a2f7e5dd5b67b95f1f` |
| FROZEN_SEND_FAIL | FROZEN_ALICE_TO_BOB_REVERT | `0x2efe8aa311146402be477ffd558a15c523196e16df8caabce2060472b8baa968` |
| FROZEN_RECEIVE_FAIL | FROZEN_BOB_TO_ALICE_REVERT | `0x3fa250666e45875f4b89f7f567bb067d18c13dd8f08d2204e704ab7a44782398` |
| MAX_BALANCE_REJECT | COMPLIANCE_MAX_BALANCE_OVER_CAP_REVERT | `0x0276a7880065d7488896e0c3cb1fa458114ebe5354a9f38ba4cb7c5291b1ed16` |
| TAG_DENY_FAIL | TAG_ALLOWLIST_TEST_POLICY | `0x9b8ef4fb64a9c9242abd4e9614307ca167677a4497cd69190594d8c2647afe99` |

### Schema rows without a dedicated hash

These are view checks, constructor side-effects, or aggregations. **Hashes were
not invented.**

| Required testName | Result | Why no unique hash |
| --- | --- | --- |
| DEPLOY_ROLE_GRANTS | PASS | Constructors grant roles; recorded against the token deploy tx |
| ROLE_ADMIN / ROLE_ISSUER / ROLE_FREEZER / ROLE_RECOVERY | PASS | View checks of disclosed overlap |
| IDENTITY_ALICE_UNVERIFIED / IDENTITY_BOB_UNVERIFIED | PASS | View checks before VERIFY_* |
| SUPPLY_LEDGER_MATCH | PASS | Observed supply matches the mint/burn formula below |

`UNAUTHORIZED_UNFREEZE_REVERT` moved **SKIPPED → PASS**. Unfreeze-deny tx
`0xfac87c8019bc836738dc28f4361befc0fc5c5d45cb1fc93a6dd469bbf7594adf`
(status 0). Caller CHARLIE/UNAUTHORIZED
`0xadD8E3672B6EFBA5eEa6a317e144D5D4F8E07813`, target ALICE
`0x24A70d01E3440A8B291a0eAE148ADab6640779B1`. Alice remained `frozen=true`
after. PUBLIC TESTNET BEHAVIORAL MATRIX remains **PASS**. OVERALL remains
**TESTNET REHEARSAL INCOMPLETE** (Etherscan Exact Match is not confirmed).

## Supply ledger / on-chain state

Formula: `0 + mint 1000e18 + mint 1e18 (below cap) + mint 1e18 (tagged bob) − burn 1e18 = 1001e18`.

Transfers, freeze, unfreeze, and `forceTransfer` contribute **0** to supply.
Observed `totalSupply` **1001000000000000000000**. **PASS SUPPLY_LEDGER_MATCH**.

Files: `artifacts/sepolia/supply-ledger.json`, `artifacts/sepolia/onchain-state.json`.

Final RPC state (block ~11581660):

| Field | Value |
| --- | --- |
| totalSupply | 1001000000000000000000 (1001e18) |
| ALICE | 0, frozen true |
| BOB | 200e18 |
| CHARLIE | 801e18 |
| maxBalance | 0 |
| tagsEnforced | false |

Holder split check: ALICE 0 + BOB 200e18 + CHARLIE 801e18 = 1001e18.

CHARLIE 801e18 = forceTransfer 800e18 (unverified replacement, AFR-06) + issuer
mint 1e18 below cap (mint skips verified-registry, AFR-05). CHARLIE was never
listed.

## Verification

- **Sourcify:** `exact_match` for all three contracts. Links in the deploy table.
- **Etherscan:** **NOT verified** for all three. Sourcify-to-Etherscan relay hit
  the daily 500 submission cap. Do not claim Etherscan verification.

## Secret scan

This evidence PR commits public addresses, public tx hashes, and Sourcify URLs
only. **No** `.env`, keystores, private keys, API keys, or Foundry
`broadcast/` / `run-latest` JSON.

`.gitignore` still covers `.env`, `.env.*` (`!.env.example`), `*.pem`, `*.key`,
`broadcast/`.

## Honesty

Public testnet engineering rehearsal only.
Not a product. Not an audit. Not ERC-3643 certified. Not KYC.
Not USD-backed. Not production ready. Not a compliant RWA issuance.
Role overlap is a faucet limitation. Etherscan verification did not succeed.
OVERALL remains **TESTNET REHEARSAL INCOMPLETE**.
