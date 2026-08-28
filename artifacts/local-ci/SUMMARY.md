# Local CI summary (terminal is authoritative)

UTC complete: 2026-08-28T01:15:26Z
forge 1.8.0 / solc 0.8.28 / evm cancun
No public-chain broadcast.

## Counts

| Command | Passed | Failed | Skipped | Notes |
| --- | --- | --- | --- | --- |
| `forge test -vvv` | 78 | 0 | 0 | 8 suites; fuzz 256; invariant 64 runs / 1600 calls / 0 reverts |
| `forge coverage` (embedded test run) | 78 | 0 | 0 | src line coverage 100% on Compliance, IdentityRegistry, PermissionedToken |
| `forge test --gas-report` | 78 | 0 | 0 | |
| `FOUNDRY_PROFILE=intense forge test -vvv` | 78 | 0 | 0 | fuzz 5000; invariant 256 runs / 12800 calls / 0 reverts |

README on main claimed 76 tests. This revision is **78** because `test/TestnetSmoke.t.sol` adds 2 tooling tests (`WrongChain` + AFPT deploy labels). Hypothesis of 76 is not assumed.

`[profile.intense.invariant] fail_on_revert = false` left unchanged (accepted residual). Intense run still recorded 0 reverts.

PermissionedToken runtime size: **4,872 bytes** (unchanged; `src/` not modified).

On-chain: NOT EXECUTED — no public-chain broadcast in this PR
