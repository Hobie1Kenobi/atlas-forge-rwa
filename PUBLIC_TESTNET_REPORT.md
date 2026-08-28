ATLAS FORGE RWA PUBLIC TESTNET ENGINEERING REHEARSAL.
This deployment does not represent a live security, investment product, USD-backed asset, audited protocol, KYC platform, or production issuance.

# Public testnet report

Ethereum Sepolia (chainId `11155111`) and Base Sepolia (chainId `84532`)
engineering rehearsals of AFPT. Neither is a live issuance, **not** USD-backed,
**not** an audit, **not** ERC-3643, and **not** KYC. There is **no** mainnet
deploy in this report. Token name/symbol on-chain: **Atlas Forge Permissioned
Test Token** / **AFPT**. That is a label, not a USD peg, reserve, redeem, or AUM
figure.

`src/` was **not** modified (deploy bytecode still
`0807cdab8acb6769eaf67c39cc6b7ad5b2e9770f`). Evidence JSON is hand-written and
sanitized. Foundry `broadcast/` / `run-latest` JSON was **not** committed (it
can contain secrets). Foundry `contractName` in broadcast JSON was misaligned;
contract identities below trust on-chain receipts, explorer `#code` pages, and
Sourcify `exact_match` pages (additional).

Ethereum Sepolia AFPT remains under rehearsal deployer
`0xB2636381c7a501DfB316ea786a2c689324318b01`. Those hashes are **not** rewritten.
Base Sepolia was executed 2026-08-28 UTC under operator
`0xEBd956F5c8C4b32752d87D62314F9431Dc0449e9`.

## Release gate (honest)

| Gate | Result |
| --- | --- |
| PUBLIC TESTNET BEHAVIORAL MATRIX | **PASS** (Ethereum Sepolia and Base Sepolia) |
| SOURCIFY | **PASS** (all three `exact_match` on both chains; additional proof) |
| ETHERSCAN (Ethereum Sepolia) | **PASS** — Exact Match confirmed 2026-08-28 via `forge verify-contract --chain sepolia --verifier etherscan --watch` (solc 0.8.28, optimizer 200, cancun). Recruiter-facing proof. |
| BASESCAN / Etherscan v2 (Base Sepolia) | **PASS** — `forge verify-contract --chain 84532 --verifier etherscan --watch` → `Pass - Verified` for all three. Etherscan v2 `getsourcecode` chainid=84532: ContractName matches, CompilerVersion `v0.8.28+commit.7893614a`, OptimizationUsed `1`, Runs `200`, EVMVersion `cancun`, SimilarMatch empty, SourceCode nonempty. Recruiter-facing: Basescan `#code` links. HTML scrape of Basescan returned **403 WAF** from the operator box; this report does **not** claim an independently rendered HTML Exact Match. |
| EVIDENCE PACKAGE | Ethereum Sepolia `a825081` (behavioral) + Exact Match flip on `main`. This PR is the Base Sepolia evidence package. |
| OVERALL (Ethereum Sepolia) | **TESTNET REHEARSAL COMPLETE — NOT AN ISSUANCE** |
| OVERALL (Base Sepolia) | **TESTNET REHEARSAL COMPLETE — NOT AN ISSUANCE** (executed 2026-08-28; not a mainnet deploy) |

Still **not** an issuance, **not** an audit, **not** ERC-3643, **not** KYC, **not** a USD peg. Not production ready. Not a compliant RWA product. Not a mainnet deploy.

## Ethereum Sepolia

## Environment

| Field | Value |
| --- | --- |
| Repo | https://github.com/Hobie1Kenobi/atlas-forge-rwa |
| Branch | `cursor/etherscan-exact-match-docs-46f8` (verification-status flip) |
| Git commit deployed from | `0807cdab8acb6769eaf67c39cc6b7ad5b2e9770f` (deploy bytecode) |
| Evidence package commit | `a82508147da003a5ab98e40f7455812cc5cd2aa6` (public testnet report on `main`) |
| Etherscan Exact Match | confirmed 2026-08-28 |
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

| Contract | Address | Bytecode | Deploy tx | Block | gasUsed | Etherscan | Sourcify |
| --- | --- | --- | --- | --- | --- | --- | --- |
| IdentityRegistry | `0x57B7434E34702fFEA2825D6F23B651c20207E814` | 1535 bytes | `0x0b0dc5791e85870d925a324e81bb358d5279c9669065523c18cfe853ba0c130e` | 11581611 | 441695 | [Exact Match](https://sepolia.etherscan.io/address/0x57B7434E34702fFEA2825D6F23B651c20207E814#code) | [exact_match](https://repo.sourcify.dev/11155111/0x57B7434E34702fFEA2825D6F23B651c20207E814) (additional) |
| Compliance | `0xB050a43e5Dd7dF0Ad626cAF9f179549bF4deFD12` | 2285 bytes | `0xaa85254e2cb02a4a5c9b7f41063993ed0c8e2bd117f26fe76d0f17c38b5690fe` | 11581611 | 604023 | [Exact Match](https://sepolia.etherscan.io/address/0xB050a43e5Dd7dF0Ad626cAF9f179549bF4deFD12#code) | [exact_match](https://repo.sourcify.dev/11155111/0xB050a43e5Dd7dF0Ad626cAF9f179549bF4deFD12) (additional) |
| PermissionedToken | `0x1FF6c5A4890C9F3ef499732fC82Fc270E1EA6759` | 4872 bytes | `0x714b930896440a17d429c0cb6964ef58ee96f7869b2436c8f31a52b6f6edd18c` | 11581611 | 1319019 | [Exact Match](https://sepolia.etherscan.io/address/0x1FF6c5A4890C9F3ef499732fC82Fc270E1EA6759#code) | [exact_match](https://repo.sourcify.dev/11155111/0x1FF6c5A4890C9F3ef499732fC82Fc270E1EA6759) (additional) |

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
after. PUBLIC TESTNET BEHAVIORAL MATRIX remains **PASS**. OVERALL is
**TESTNET REHEARSAL COMPLETE — NOT AN ISSUANCE** (Etherscan Exact Match
confirmed 2026-08-28).

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

- **Etherscan:** **Exact Match** for all three, confirmed 2026-08-28 via
  `forge verify-contract --chain sepolia --verifier etherscan --watch`
  (`Pass - Verified`). Compiler v0.8.28+commit.7893614a, optimizer 200, EVM
  cancun, SimilarMatch empty. HTML on each address page: `Source Code Verified`
  + `Exact Match`. Recruiter-facing proof. Links in the deploy table (`#code`).
- **Sourcify:** `exact_match` for all three (additional). Links in the deploy table.

## Secret scan

This evidence PR commits public addresses, public tx hashes, Etherscan Exact
Match `#code` URLs, and Sourcify URLs only. **No** `.env`, keystores, private
keys, API keys, or Foundry `broadcast/` / `run-latest` JSON.

`.gitignore` still covers `.env`, `.env.*` (`!.env.example`), `*.pem`, `*.key`,
`broadcast/`.

## Honesty (Ethereum Sepolia)

Public testnet engineering rehearsal only.
Not a product. Not an audit. Not ERC-3643 certified. Not KYC.
Not USD-backed. Not production ready. Not a compliant RWA issuance.
Role overlap is a faucet limitation. Etherscan Exact Match confirmed
2026-08-28. OVERALL is **TESTNET REHEARSAL COMPLETE — NOT AN ISSUANCE**.
Ethereum Sepolia hashes above are unchanged.

---

## Base Sepolia

Public testnet engineering rehearsal on Base Sepolia (chainId `84532`),
executed **2026-08-28 UTC**. This is **not** a live issuance, **not**
USD-backed, **not** an audit, **not** ERC-3643, **not** KYC, and **not** a
mainnet deploy. On-chain label: **Atlas Forge Permissioned Test Token** /
**AFPT**.

Creator / DEFAULT_ADMIN / ISSUER / FREEZER / RECOVERY is Hobie's Agentic
Swarm Marketplace operator EOA
`0xEBd956F5c8C4b32752d87D62314F9431Dc0449e9`. `ACK_ROLE_OVERLAP=true` (same
EOA holds all four roles). This is a **showcase wallet for testnet
validation**, not production IAM. ALICE / BOB / CHARLIE are separate
rehearsal actors (same addresses as the Ethereum Sepolia rehearsal), funded
with a sliver of Base Sepolia ETH from the operator.

Deploy bytecode commit is still `0807cdab8acb6769eaf67c39cc6b7ad5b2e9770f`
(`src/` unchanged vs that commit). Runtime sizes match Ethereum Sepolia:
IdentityRegistry 1535, Compliance 2285, PermissionedToken 4872. solc 0.8.28,
optimizer 200, Cancun.

### Environment

| Field | Value |
| --- | --- |
| Repo | https://github.com/Hobie1Kenobi/atlas-forge-rwa |
| Network | Base Sepolia |
| chainId | 84532 |
| Date | 2026-08-28 UTC |
| Git commit deployed from | `0807cdab8acb6769eaf67c39cc6b7ad5b2e9770f` (deploy bytecode; `src/` unchanged) |
| Operator / creator | `0xEBd956F5c8C4b32752d87D62314F9431Dc0449e9` |
| Deploy block | 46060034 (all three CREATE) |
| solc | 0.8.28 |
| evm_version | cancun |
| optimizer | true, 200 runs |

Local CI is unchanged: `forge test` **78 passed**; `src/` untouched.

### Role overlap (disclosed)

| Role | Address |
| --- | --- |
| ADMIN = ISSUER = FREEZER = RECOVERY (operator) | `0xEBd956F5c8C4b32752d87D62314F9431Dc0449e9` |
| ALICE | `0x24A70d01E3440A8B291a0eAE148ADab6640779B1` |
| BOB | `0x6BA6855b0C35A556A334326B5D8Eb494830e0dE5` |
| CHARLIE = UNAUTHORIZED | `0xadD8E3672B6EFBA5eEa6a317e144D5D4F8E07813` |

`ACK_ROLE_OVERLAP=true`. Showcase operator EOA, **not** production IAM.
Documented roles remain issuer-is-god (AFR-04 through AFR-07), not hidden
vulnerabilities.

Gas fund (operator → actors, 0.00003 ETH each):

| Actor | Tx |
| --- | --- |
| ALICE | `0xb2279459262cd697e7bc134a60ae98b80cff3f8a3baaa5bc4ac9220d2660a7e9` |
| BOB | `0xeae624bcf5619d3383dca38fc69b1c9cdcca1cdfedace5b927993d158bf439f3` |
| CHARLIE | `0x033f249e627fb5e995703e0e0e487cca72da53b2912841599f4c8bc763ebe87e` |

### On-chain deployment

All three CREATE in block **46060034**, creator `0xEBd9…449e9`.

| Contract | Address | Bytecode | Deploy tx | Block | gasUsed | Basescan | Sourcify |
| --- | --- | --- | --- | --- | --- | --- | --- |
| IdentityRegistry | `0x79f550d079065Ef10861F957c7F9febDE8929d8e` | 1535 bytes | `0x8947f23c4b0ce7a6bf97176224247a2308fe5be92f7a13d755bc061aa99556e5` | 46060034 | 441695 | [#code](https://sepolia.basescan.org/address/0x79f550d079065Ef10861F957c7F9febDE8929d8e#code) | [exact_match](https://repo.sourcify.dev/84532/0x79f550d079065Ef10861F957c7F9febDE8929d8e) (additional) |
| Compliance | `0x93527A8eFd77bCcFb1D539757dcC2150321BbC4A` | 2285 bytes | `0x8e3ad6efcecc1b8fd40fa211089185c9d822182dc3f0ca91ac735d2b6f26a3cb` | 46060034 | 604023 | [#code](https://sepolia.basescan.org/address/0x93527A8eFd77bCcFb1D539757dcC2150321BbC4A#code) | [exact_match](https://repo.sourcify.dev/84532/0x93527A8eFd77bCcFb1D539757dcC2150321BbC4A) (additional) |
| PermissionedToken | `0xaa923f43b48eCAC2FD8AB16f65DEEFbA9e3d5Df2` | 4872 bytes | `0x60a67742dea7a293a499fb4ff816a40949c98aa98c28398f8609f93c424c2e28` | 46060034 | 1319019 | [#code](https://sepolia.basescan.org/address/0xaa923f43b48eCAC2FD8AB16f65DEEFbA9e3d5Df2#code) | [exact_match](https://repo.sourcify.dev/84532/0xaa923f43b48eCAC2FD8AB16f65DEEFbA9e3d5Df2) (additional) |

On-chain `name()` / `symbol()`: **Atlas Forge Permissioned Test Token** / **AFPT**.
`registry()` and `compliance()` on the token match the two addresses above.
`DEFAULT_ADMIN` `hasRole` true for `0xEBd956F5c8C4b32752d87D62314F9431Dc0449e9`.

Sanitized record: `deployments/base-sepolia.json`.

### Behavioral matrix

Expected user-path reverts were submitted as real txs with **status 0**. Those
failures are **positive evidence** (PASS). Full table:
`artifacts/base-sepolia/testnet-results.json`.

**Nonce-retry (honest):** some happy-path txs were retried after RPC nonce
collisions. Evidence below uses the **successful** hashes only, not failed
attempts. Extra unfreeze before mint repaired freeze-before-mint from the
collision pass (`UNFREEZE_FOR_MINT`).

#### Successful txs (status 1)

| Operator name | Required testName | Tx |
| --- | --- | --- |
| VERIFY_ALICE | IDENTITY_SET_VERIFIED_ALICE | `0x66b4af199dcd7e63709b4ec21eeb7fb7395e5d05f55ab563906063cee4a58ee1` |
| VERIFY_BOB | IDENTITY_SET_VERIFIED_BOB | `0x40995356dcfa1ffdcbe8360ad5d6e5e842bf133e6179a818c414b849dd5f2c73` |
| MINT_SUCCESS | MINT_ALICE_1000 / MINT_SUPPLY_DELTA | `0x3d0156d98e5d2fdd028ffd520eae0f289d24a2af39beeaca0025f8eef28e5585` (1000e18 to ALICE; successful hash after nonce-collision retries) |
| TRANSFER_VERIFIED_SUCCESS | TRANSFER_VERIFIED_ALICE_BOB_100 / TRANSFER_SUPPLY_CONSTANT | `0x77167f6fb00e81b5c55f0e87a0cefabfd8b18fdc14e21eed16571904ca9a6846` (100e18 ALICE→BOB) |
| FREEZE_SUCCESS | FREEZE_ALICE | `0x8ca6cf039e2ef14bf2c56c30b55b0911c7e919f26c599990bf31bfbc9d1eb65e` |
| UNFREEZE_SUCCESS | UNFREEZE_ALICE | `0x2bd8f0d7aa0c8f741dbe6dcafc293beee05e61f0f6a6b37efe97d1f7182a10d7` |
| UNFREEZE_FOR_MINT | (nonce-retry repair) | `0x9316ba3abfb331a51d30a3cb823405ca859b29e8c20d36f4365c594c50814b51` |
| TRANSFER_AFTER_UNFREEZE | TRANSFER_AFTER_UNFREEZE | `0xd86e126fe6004c567bf68bbcff44e6511fbc4cef009f7b4260181f0e590589b1` (another 100e18 ALICE→BOB) |
| FREEZE_BEFORE_RECOVERY | (related to FORCE_TRANSFER) | `0x9b171e5822bf6dd826f80bfcb3754773a8b4bc56d4301e23f0066c3f6ecbe6f9` |
| FORCE_TRANSFER_SUCCESS | FORCE_TRANSFER_FROZEN_ALICE_TO_REPLACEMENT / FORCE_TRANSFER_SUPPLY_CONSTANT | `0xb77fab11696046419c84ceeb497510d1d487b91c14624c704972c9eb0b6f5e19` (ALICE 800e18 → CHARLIE/unverified replacement; supply unchanged) |
| MAX_BALANCE_SET | (related to COMPLIANCE_MAX_BALANCE_*) | `0x7abe54ea76bf562ffe74d2934be731c7488f341c59effbb6c1c00d86b33b3144` |
| MAX_BALANCE_PASS | COMPLIANCE_MAX_BALANCE_BELOW_CAP | `0xbacf869875628a41ff6fb446fdd88dc07816b798567fa2985aceaa87f5403feb` (1e18 to CHARLIE) |
| CLEAR_MAX | (related) | `0x5758027a5f766a4c5ad8d565acd84f0bd4926028d29f8c02d0ed3cdb1a725abf` |
| TAG_ALLOW | TAG_ALLOWLIST_TEST_POLICY | `0xceb21214816a05afac1f9581c6fc9375ab8ef3d7d4d02b13f47a7a0842ea2704` (keccak `ATLAS_TEST_POLICY_TAG`; demo code only) |
| SET_BOB_TAG | TAG_ALLOWLIST_TEST_POLICY | `0x14593e35f24d35f4d44aef097d3c3ea272816cf187a31357d80b093aa07ce723` |
| TAGS_ON | TAG_ALLOWLIST_TEST_POLICY | `0xba5e097ec9d02d1635396e02b74f9950d0e21eba51f00f4ed843a2c5f5a663e4` |
| TAG_ALLOW_PASS | TAG_ALLOWLIST_TEST_POLICY | `0xf804a1498e6c827adae458e164aeee8c6df3044b52b41ea6b1089a9a7c9f157e` (mint 1e18 BOB) |
| TAGS_OFF | TAG_ALLOWLIST_TEST_POLICY | `0x053310f97344d75d9b55c75c1c910fe95e4ff341837ed6c2adf3b56a8c74b2f2` |
| BURN_SUCCESS | ISSUER_BURN | `0x48522b0452d453313ac5daf9e7d8f9526fe8209865bf68ec26aacd1030e25590` (1e18 from BOB) |

#### Failed txs (status 0, positive evidence)

| Operator name | Required testName | Tx |
| --- | --- | --- |
| UNAUTHORIZED_MINT_FAIL | UNAUTHORIZED_MINT_REVERT | `0xfeea92fd91e2b1e41a363426ebdbe40824b5572182d114cb86941647839b4ebc` |
| UNAUTHORIZED_FREEZE_FAIL | UNAUTHORIZED_FREEZE_REVERT | `0x77a39a738c548ed10c6d6a7e0c89d51d4e7c5d13d8da94fec2ad84a9a844b864` |
| UNAUTHORIZED_SET_VERIFIED_FAIL | UNAUTHORIZED_SET_VERIFIED_REVERT | `0xdd0b39e15a96f036880195634a0e1ec4220eabc477785456cd313972bf73ceb0` |
| UNAUTHORIZED_FORCE_TRANSFER_FAIL | UNAUTHORIZED_FORCE_TRANSFER_REVERT | `0x84126c7d39a1cd82b2bcf0908bde4a42b5727316d3e28a0f0903b275634cb41e` |
| UNAUTHORIZED_BURN_FAIL | UNAUTHORIZED_BURN_REVERT | `0x4d444ff17264e026220a37637c3b24d0e63444f400bdb0e52d0adf810968cc16` |
| UNAUTHORIZED_UNFREEZE_FAIL | UNAUTHORIZED_UNFREEZE_REVERT | `0x50495133ede2c4e5338206cea0e125c5bb8bc5254a2ed3ad8c4562eae01c544c` |
| TRANSFER_UNVERIFIED_FAIL ALICE→CHARLIE | TRANSFER_UNVERIFIED_ALICE_CHARLIE_REVERT | `0xd1febfa6e4bec7e07c28d8ede85d6cad9ca6641cc4e1727f4423c6fd4e95eb34` |
| TRANSFER_UNVERIFIED_FAIL CHARLIE→ALICE | TRANSFER_UNVERIFIED_CHARLIE_ALICE_REVERT | `0x3111631231c6ef921a2f06a172efecae3d6ab140384d7d5778f982a91db7c29f` |
| FROZEN_SEND_FAIL | FROZEN_ALICE_TO_BOB_REVERT | `0x7875f9768a22acbefe6d8ebddf9007549c14f1204e4e5dde778034c4930ce125` |
| FROZEN_RECEIVE_FAIL | FROZEN_BOB_TO_ALICE_REVERT | `0xdce980573d4da3a0c6cc39a35eef16fe50886d4ed3ef56340de3037c570f65b8` |
| MAX_BALANCE_REJECT | COMPLIANCE_MAX_BALANCE_OVER_CAP_REVERT | `0x30d47eea2a434220bc523e1345d2d8f8438168e5dcd4d905e576b525759b75b9` |
| TAG_DENY_FAIL | TAG_ALLOWLIST_TEST_POLICY | `0xae66440e40ffde1a58ccdd33d28862210577635598390f770c3fa1169a1a4aec` |

`UNAUTHORIZED_UNFREEZE_FAIL` caller CHARLIE/UNAUTHORIZED
`0xadD8E3672B6EFBA5eEa6a317e144D5D4F8E07813`, target ALICE
`0x24A70d01E3440A8B291a0eAE148ADab6640779B1`. Alice stayed frozen. Status 0 is
PASS.

### Schema rows without a dedicated hash

These are view checks, constructor side-effects, or aggregations. **Hashes were
not invented.**

| Required testName | Result | Why no unique hash |
| --- | --- | --- |
| DEPLOY_ROLE_GRANTS | PASS | Constructors grant roles; recorded against the token deploy tx |
| ROLE_ADMIN / ROLE_ISSUER / ROLE_FREEZER / ROLE_RECOVERY | PASS | View checks of disclosed overlap; DEFAULT_ADMIN hasRole true for 0xEBd9 |
| IDENTITY_ALICE_UNVERIFIED / IDENTITY_BOB_UNVERIFIED | PASS | View checks before VERIFY_* |
| SUPPLY_LEDGER_MATCH | PASS | Observed supply matches the mint/burn formula below |

PUBLIC TESTNET BEHAVIORAL MATRIX = **PASS**. OVERALL is
**TESTNET REHEARSAL COMPLETE — NOT AN ISSUANCE**.

### Supply ledger / on-chain state

Formula: `0 + mint 1000e18 ALICE + mint 1e18 CHARLIE (below cap) + mint 1e18 BOB (tagged) − burn 1e18 BOB = 1001e18`.

Transfers, freeze, unfreeze, and `forceTransfer` contribute **0** to supply.
Observed `totalSupply` **1001000000000000000000**. **PASS SUPPLY_LEDGER_MATCH**.

| Field | Value |
| --- | --- |
| totalSupply | 1001000000000000000000 (1001e18) |
| ALICE | 0, frozen true |
| BOB | 200e18 |
| CHARLIE | 801e18 |
| OPERATOR | 0 |
| maxBalance | 0 |
| tagsEnforced | false |

Holder split check: ALICE 0 + BOB 200e18 + CHARLIE 801e18 = 1001e18.

CHARLIE 801e18 = forceTransfer 800e18 (unverified replacement, AFR-06) + issuer
mint 1e18 below cap (mint skips verified-registry, AFR-05). CHARLIE was never
listed.

### Verification

Lead with recruiter-facing Basescan `#code` links (table above).

- **forge / Etherscan v2 API:** `forge verify-contract --chain 84532 --verifier etherscan --watch` → **Pass - Verified** for all three (confirmed 2026-08-28). Etherscan v2 `getsourcecode` chainid=84532: ContractName matches, CompilerVersion `v0.8.28+commit.7893614a`, OptimizationUsed `1`, Runs `200`, EVMVersion `cancun`, SimilarMatch **empty**, SourceCode nonempty. Empty SimilarMatch plus `Pass - Verified` is the confirmation used here.
- **HTML scrape:** Basescan returned **403 WAF** from the operator box. This report does **not** claim that Exact Match was independently rendered in HTML.
- **Sourcify:** `exact_match` for all three (additional). Links in the deploy table.

### Secret scan

This evidence PR commits public addresses, public tx hashes, Basescan `#code`
URLs, and Sourcify URLs only. **No** `.env`, keystores, private keys, API keys,
or Foundry `broadcast/` / `run-latest` JSON.

### Honesty (Base Sepolia)

Public testnet engineering rehearsal only.
Not a product. Not an audit. Not ERC-3643 certified. Not KYC.
Not USD-backed. Not production ready. Not a compliant RWA issuance.
Not a mainnet deploy. Role overlap is a showcase operator EOA, not production IAM.
OVERALL is **TESTNET REHEARSAL COMPLETE — NOT AN ISSUANCE**.
