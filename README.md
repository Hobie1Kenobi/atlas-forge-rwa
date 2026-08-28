# Atlas Forge RWA

[![forge test + fmt](https://github.com/Hobie1Kenobi/atlas-forge-rwa/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/Hobie1Kenobi/atlas-forge-rwa/actions/workflows/ci.yml)

Permissioned ERC-20 with freeze, recovery, and an identity registry. Portfolio sketch for **Smart Contract Engineer** / **RWA Tokenization** roles. **Not** an issuance, **not** an audit, **not** ERC-3643, **not** a USD peg.

| Recruiter fact (20s) | Value |
| --- | --- |
| Local tests | `forge test` — CI badge above is [`.github/workflows/ci.yml`](https://github.com/Hobie1Kenobi/atlas-forge-rwa/blob/main/.github/workflows/ci.yml) (`forge test` + `forge fmt --check`) |
| Evidence commit | [`a825081`](https://github.com/Hobie1Kenobi/atlas-forge-rwa/commit/a82508147da003a5ab98e40f7455812cc5cd2aa6) (`a82508147da003a5ab98e40f7455812cc5cd2aa6`) Ethereum Sepolia; this PR is Base Sepolia |
| Deploy bytecode | [`0807cda`](https://github.com/Hobie1Kenobi/atlas-forge-rwa/commit/0807cdab8acb6769eaf67c39cc6b7ad5b2e9770f) (`0807cdab8acb6769eaf67c39cc6b7ad5b2e9770f`) |
| Network | Ethereum Sepolia (chainId 11155111) |
| On-chain label | Atlas Forge Permissioned Test Token / **AFPT** (label only, not a dollar) |
| Etherscan | **Exact Match** confirmed 2026-08-28 — [IdentityRegistry](https://sepolia.etherscan.io/address/0x57B7434E34702fFEA2825D6F23B651c20207E814#code) · [Compliance](https://sepolia.etherscan.io/address/0xB050a43e5Dd7dF0Ad626cAF9f179549bF4deFD12#code) · [PermissionedToken](https://sepolia.etherscan.io/address/0x1FF6c5A4890C9F3ef499732fC82Fc270E1EA6759#code) |
| Sourcify (additional) | `exact_match` — [IdentityRegistry](https://repo.sourcify.dev/11155111/0x57B7434E34702fFEA2825D6F23B651c20207E814) · [Compliance](https://repo.sourcify.dev/11155111/0xB050a43e5Dd7dF0Ad626cAF9f179549bF4deFD12) · [PermissionedToken](https://repo.sourcify.dev/11155111/0x1FF6c5A4890C9F3ef499732fC82Fc270E1EA6759) |
| Base Sepolia | chainId 84532 · operator [`0xEBd956F5c8C4b32752d87D62314F9431Dc0449e9`](https://sepolia.basescan.org/address/0xEBd956F5c8C4b32752d87D62314F9431Dc0449e9) · **AFPT** (not an issuance) · Basescan Exact Match [IdentityRegistry](https://sepolia.basescan.org/address/0x79f550d079065Ef10861F957c7F9febDE8929d8e#code) · [Compliance](https://sepolia.basescan.org/address/0x93527A8eFd77bCcFb1D539757dcC2150321BbC4A#code) · [PermissionedToken](https://sepolia.basescan.org/address/0xaa923f43b48eCAC2FD8AB16f65DEEFbA9e3d5Df2#code) |
| Overall | **TESTNET REHEARSAL COMPLETE — NOT AN ISSUANCE** (Ethereum Sepolia and Base Sepolia; not a mainnet deploy) |

> **Honest label.** This is **NOT** legally compliant securities infrastructure, **NOT** a broker-dealer product, **NOT** ERC-3643 certified, and **NOT** a KYC vendor integration. It is an engineering sketch of restriction + registry patterns a hiring manager can `forge test` in three commands. No fake AUM, no fake audit, no fake clients.

This repo is **production-shaped** (AccessControl roles, `_update` hook on every supply path, Foundry unit/fuzz/invariants) and **not production-certified**. There is no paid audit, no ERC-3643 certificate, and no AUM. Ethereum Sepolia and Base Sepolia engineering rehearsals exist; neither is a live issuance. There is no mainnet deploy. Internal review notes live in [docs/findings/](docs/findings/README.md). `forge test` is the local deliverable.

## Why this is not a tutorial ERC-20

Typical “my first token” repos: `transfer` is open, owner mint is a footnote, freeze is missing or silent god-mode, and tests are happy-path. This one does the opposite:

- Every `transfer` / `transferFrom` / `mint` / `burn` lands in `_update` and hits identity + freeze + compliance, except the **documented** issuer exceptions.
- Freeze, `forceTransfer`, and issuer mint/burn are **issuer-is-god**. That is the point of a permissioned RWA token, not a hidden bug. The README and [docs/threat-model.md](docs/threat-model.md) say so in plain language.
- `IdentityRegistry` stores a `bytes32 attestationHash`, not PII. It is not KYC, not ONCHAINID, not a transfer agent.
- `Compliance` max-balance and tag allowlist are demo policy knobs (country/class *codes*), not geofencing or sanctions screening.
- Tests are named after the behavior they lock. Fuzz hammers random transfer attempts. An invariant handler proves freeze/`forceTransfer` do not change `totalSupply`.

## Architecture

```
holders ──ERC-20──► PermissionedToken
                       │ _update() on transfer / transferFrom / mint / burn
                       ├─ IdentityRegistry.isVerified  (user path)
                       ├─ frozen[account]              (user path, mint, burn)
                       └─ Compliance.validateTransfer  (max-balance, optional tags)

Roles (AccessControl, single admin in v1):
  DEFAULT_ADMIN  grants the others
  ISSUER         mint, burn, setVerified, compliance knobs, forceTransfer
  FREEZER        freeze / unfreeze
  RECOVERY       forceTransfer (with ISSUER)
```

`forceTransfer` moves balances. It does not mint or burn. It calls `ERC20._update` directly so it bypasses verified, freeze, max-balance, and tags — a lost-key recovery can land tokens on a replacement wallet. User transfers never get that bypass.

v1 constructors grant `DEFAULT_ADMIN` plus ISSUER / FREEZER / RECOVERY. A production fork should put DEFAULT_ADMIN on a timelock (atlas-forge-vault already shows the 48h pattern). This sketch does not duplicate that timelock. Default deploy name `AFPT` is a **label**, not a USD peg. The old `afpUSD` fallback looked like a dollar claim and was a mistake-class risk.

## Install and test

Requires [Foundry](https://book.getfoundry.sh/getting-started/installation).

```bash
git clone https://github.com/Hobie1Kenobi/atlas-forge-rwa.git
cd atlas-forge-rwa
git submodule update --init --recursive
forge test
```

Optional: `forge coverage` (restriction/auth, not a vanity %) and `forge test --gas-report`. Internal findings: [docs/findings/README.md](docs/findings/README.md).

## Invariants

Locked in `test/PermissionedToken.t.sol`, `test/Fuzz.t.sol`, `test/Invariant.t.sol`:

1. **Supply** — `totalSupply` is unchanged by freeze or `forceTransfer`. Only ISSUER mint/burn changes supply. `forceTransfer` moves; it never mints or burns.
2. **Registry** — an unverified address cannot receive or send on `transfer` / `transferFrom`, except ISSUER mint and `forceTransfer`.
3. **Freeze** — a frozen address cannot send or receive on the user path, mint, or burn. `forceTransfer` may still move frozen balances (recovery).
4. **Mint** — only ISSUER mints.
5. **Auth** — unauthorized `freeze` / `forceTransfer` / `setVerified` revert.

## Admin powers (issuer-is-god, on purpose)

| Action | Role | Bypass |
| --- | --- | --- |
| `mint` / `burn` | ISSUER | verified-registry (not freeze, not max-balance/tags on mint) |
| `setVerified(account, bool, attestationHash)` | ISSUER on `IdentityRegistry` | n/a |
| `setMaxBalance` / tags | ISSUER on `Compliance` | n/a |
| `freeze` / `unfreeze` | FREEZER | n/a — does not move tokens |
| `forceTransfer(from, to, amount)` | RECOVERY or ISSUER | verified, freeze, max-balance, tags. Still cannot mint/burn |

A compromised ISSUER can mint unbounded supply and force-move any balance. A compromised FREEZER can trap user transfers (recovery still works). A compromised RECOVERY can seize tokens onto any address. That is the trust model. Do not ship with an EOA admin.

## Tests

`forge test` on this revision: **78 passed**.

| File | What it locks | Result |
| --- | --- | --- |
| `PermissionedToken.t.sol` | supply, unverified send/receive, freeze, mint auth, unauthorized freeze/force/setVerified, recovery from frozen | 36 passed |
| `IdentityRegistry.t.sol` | ISSUER listing, hash-not-PII, unauthorized `setVerified`, constructor role grant, zero address | 8 passed |
| `Compliance.t.sol` | max-balance (including self-transfer), tag allowlist (demo codes), forceTransfer bypasses cap/tags | 13 passed |
| `AcceptedDesign.t.sol` | accepted residuals + deploy when caller is not admin | 11 passed |
| `Fuzz.t.sol` | random `transfer` / `transferFrom`; forceTransfer preserves supply | 7 passed, 256 runs each |
| `Invariant.t.sol` | stateful handler: supply = mint − burn; frozen user path reverts | 64 runs, 1600 calls, **0 reverts**, 3 invariants |

Not gas-golfed. `PermissionedToken` runtime size **4,872 bytes** (solc 0.8.28, optimizer 200, Cancun). Re-run locally; do not treat medians as SLAs.

Internal A5 notes (not a paid audit): [docs/findings/README.md](docs/findings/README.md).

## Public testnet engineering rehearsal on Ethereum Sepolia

Public testnet facts. Recruiter-facing proof is **Etherscan Exact Match**
(confirmed 2026-08-28). Sourcify `exact_match` is additional. This is **not** an
issuance.

| Field | Value |
| --- | --- |
| Network | Ethereum Sepolia (chainId 11155111) |
| Date | 2026-08-27 CT / 2026-08-28 UTC |
| Evidence commit | [`a825081`](https://github.com/Hobie1Kenobi/atlas-forge-rwa/commit/a82508147da003a5ab98e40f7455812cc5cd2aa6) |
| Deploy bytecode | [`0807cda`](https://github.com/Hobie1Kenobi/atlas-forge-rwa/commit/0807cdab8acb6769eaf67c39cc6b7ad5b2e9770f) |
| Local tests | `forge test` 78 passed; intense profile 78 passed |
| IdentityRegistry | [`0x57B7434E34702fFEA2825D6F23B651c20207E814`](https://sepolia.etherscan.io/address/0x57B7434E34702fFEA2825D6F23B651c20207E814#code) (Etherscan Exact Match; [Sourcify](https://repo.sourcify.dev/11155111/0x57B7434E34702fFEA2825D6F23B651c20207E814) additional) |
| Compliance | [`0xB050a43e5Dd7dF0Ad626cAF9f179549bF4deFD12`](https://sepolia.etherscan.io/address/0xB050a43e5Dd7dF0Ad626cAF9f179549bF4deFD12#code) (Etherscan Exact Match; [Sourcify](https://repo.sourcify.dev/11155111/0xB050a43e5Dd7dF0Ad626cAF9f179549bF4deFD12) additional) |
| PermissionedToken | [`0x1FF6c5A4890C9F3ef499732fC82Fc270E1EA6759`](https://sepolia.etherscan.io/address/0x1FF6c5A4890C9F3ef499732fC82Fc270E1EA6759#code) (Etherscan Exact Match; [Sourcify](https://repo.sourcify.dev/11155111/0x1FF6c5A4890C9F3ef499732fC82Fc270E1EA6759) additional) |

On-chain label: Atlas Forge Permissioned Test Token / AFPT. **Etherscan Exact
Match** confirmed 2026-08-28. AFPT is not a dollar. This is not an issuance, not
an audit, not ERC-3643, and not KYC. Full evidence:
[PUBLIC_TESTNET_REPORT.md](PUBLIC_TESTNET_REPORT.md),
[deployments/sepolia.json](deployments/sepolia.json). Overall:
**TESTNET REHEARSAL COMPLETE — NOT AN ISSUANCE**.

## Public testnet engineering rehearsal on Base Sepolia

Public testnet facts. Recruiter-facing proof is the Basescan `#code` pages
below (forge `Pass - Verified` + Etherscan v2 API, SimilarMatch empty,
confirmed 2026-08-28). Sourcify `exact_match` is additional. This is **not**
an issuance and **not** a mainnet deploy. Operator EOA
`0xEBd956F5c8C4b32752d87D62314F9431Dc0449e9` holds ADMIN/ISSUER/FREEZER/RECOVERY
(`ACK_ROLE_OVERLAP=true`; showcase wallet, not production IAM).

| Field | Value |
| --- | --- |
| Network | Base Sepolia (chainId 84532) |
| Date | 2026-08-28 UTC |
| Deploy bytecode | [`0807cda`](https://github.com/Hobie1Kenobi/atlas-forge-rwa/commit/0807cdab8acb6769eaf67c39cc6b7ad5b2e9770f) (`src/` unchanged) |
| Operator | [`0xEBd956F5c8C4b32752d87D62314F9431Dc0449e9`](https://sepolia.basescan.org/address/0xEBd956F5c8C4b32752d87D62314F9431Dc0449e9) |
| IdentityRegistry | [`0x79f550d079065Ef10861F957c7F9febDE8929d8e`](https://sepolia.basescan.org/address/0x79f550d079065Ef10861F957c7F9febDE8929d8e#code) (Basescan Exact Match; [Sourcify](https://repo.sourcify.dev/84532/0x79f550d079065Ef10861F957c7F9febDE8929d8e) additional) |
| Compliance | [`0x93527A8eFd77bCcFb1D539757dcC2150321BbC4A`](https://sepolia.basescan.org/address/0x93527A8eFd77bCcFb1D539757dcC2150321BbC4A#code) (Basescan Exact Match; [Sourcify](https://repo.sourcify.dev/84532/0x93527A8eFd77bCcFb1D539757dcC2150321BbC4A) additional) |
| PermissionedToken | [`0xaa923f43b48eCAC2FD8AB16f65DEEFbA9e3d5Df2`](https://sepolia.basescan.org/address/0xaa923f43b48eCAC2FD8AB16f65DEEFbA9e3d5Df2#code) (Basescan Exact Match; [Sourcify](https://repo.sourcify.dev/84532/0xaa923f43b48eCAC2FD8AB16f65DEEFbA9e3d5Df2) additional) |

On-chain label: Atlas Forge Permissioned Test Token / AFPT. AFPT is not a
dollar. This is not an issuance, not an audit, not ERC-3643, and not KYC.
Full evidence: [PUBLIC_TESTNET_REPORT.md](PUBLIC_TESTNET_REPORT.md),
[deployments/base-sepolia.json](deployments/base-sepolia.json). Overall:
**TESTNET REHEARSAL COMPLETE — NOT AN ISSUANCE**.

## Deployments

Ethereum Sepolia rehearsal addresses are in [deployments/sepolia.json](deployments/sepolia.json). Base Sepolia rehearsal addresses are in [deployments/base-sepolia.json](deployments/base-sepolia.json). Neither rehearsal is a live issuance. `script/Deploy.s.sol` broadcasts the three contracts; constructors grant roles. Running it does not make this a security. Default `AFPT` is a label, not a USD claim.

## Honest limitations (first-class)

- Not a paid audit. Not ERC-3643 certified. Internal notes: [docs/findings/](docs/findings/README.md).
- Not a KYC/AML product. `attestationHash` is a `bytes32` the issuer chose. The chain cannot tell whether anyone was identified.
- Tag allowlist is a demo `bytes32` switch. It is not geofencing, not OFAC, not accredited-investor logic.
- Issuer-is-god: mint, burn, freeze, and `forceTransfer` can seize or inflate. That is the design.
- v1 DEFAULT_ADMIN is a single address, not a 48h timelock.
- Default token name/symbol `AFPT` is a label, not a USD peg or AUM figure. The old `afpUSD` string looked like a dollar claim (mistake-class risk).
- No pause, no upgradeability, no snapshot/dividends, no on-chain identity claims, no privacy.
- No bug bounty, no on-call, no mainnet invariant bot. No fake AUM.

## Mapping to job titles

| Title | What in this repo maps |
| --- | --- |
| Smart Contract Engineer (EVM) | OZ 5 AccessControl, ERC-20 `_update` hook, custom errors, Foundry unit/fuzz/invariant |
| RWA / Tokenization Engineer | Permissioned transfers, identity registry, freeze, recovery/`forceTransfer`, compliance knobs |
| Senior Solidity (permissioned transfers) | Every supply path gated; issuer-is-god documented; tests named after locked behavior |

Maps to live 2026-08 hiring language around permissioned ERC-20 / RWA tokenization (EVM, Foundry) without pretending this sketch is a licensed product.

Author: Hobie Cunningham ([Hobie1Kenobi](https://github.com/Hobie1Kenobi)). MIT license.
