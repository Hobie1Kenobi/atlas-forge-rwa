# Atlas Forge RWA

> **Honest label.** This is **NOT** legally compliant securities infrastructure, **NOT** a broker-dealer product, **NOT** ERC-3643 certified, and **NOT** a KYC vendor integration. It is an engineering sketch of restriction + registry patterns a hiring manager can `forge test` in three commands. No fake AUM, no fake audit, no fake clients.

Permissioned ERC-20 with transfer restrictions, freeze, recovery, and an identity registry. Written as portfolio proof for **Smart Contract Engineer** / **RWA Tokenization** roles — not a tutorial token and not a live issuance.

This repo is **production-shaped** (AccessControl roles, `_update` hook on every supply path, Foundry unit/fuzz/invariants) and **not production-certified**. There is no paid audit, no ERC-3643 certificate, no AUM, and **no deployment**. Internal review notes live in [docs/findings/](docs/findings/README.md). `forge test` is the deliverable.

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

v1 constructors grant `DEFAULT_ADMIN` plus ISSUER / FREEZER / RECOVERY. A production fork should put DEFAULT_ADMIN on a timelock (atlas-forge-vault already shows the 48h pattern). This sketch does not duplicate that timelock. Default deploy name `afpUSD` is a **label**, not a USD peg.

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

`forge test` on this revision: **76 passed**.

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

## Deployments

**Not deployed** on any testnet or mainnet. There are no contract addresses to cite. `script/Deploy.s.sol` broadcasts the three contracts; constructors grant roles. Running it does not make this a security. Default `afpUSD` is a label, not a USD claim. Public testnet rehearsal tooling lives on this branch and is **not** a live issuance.

## Honest limitations (first-class)

- Not a paid audit. Not ERC-3643 certified. Internal notes: [docs/findings/](docs/findings/README.md).
- Not a KYC/AML product. `attestationHash` is a `bytes32` the issuer chose. The chain cannot tell whether anyone was identified.
- Tag allowlist is a demo `bytes32` switch. It is not geofencing, not OFAC, not accredited-investor logic.
- Issuer-is-god: mint, burn, freeze, and `forceTransfer` can seize or inflate. That is the design.
- v1 DEFAULT_ADMIN is a single address, not a 48h timelock.
- Default token name/symbol `afpUSD` is a label, not a USD peg or AUM figure.
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
