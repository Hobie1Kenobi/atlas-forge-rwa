# AFR-11 — `tagsEnforced` default-denies the zero tag

- **ID:** AFR-11
- **Severity:** Informational
- **Status:** Accepted residual
- **Component:** `Compliance.validateTransfer`

## Root cause

`tagOf[account]` defaults to `bytes32(0)`. `allowedTag[0]` defaults to `false`.
When the issuer sets `tagsEnforced = true` without first tagging holders and
allowing those tags, every user transfer (and mint to an untagged `to`) reverts
`TagNotAllowed`.

## Impact

A mis-ordered admin action pauses the user path until tags are assigned and
allowed. Issuer `forceTransfer` still works (AFR-06). This is a demo-knob
footgun, not geofencing and not a sanctions control.

## PoC test name

`test_accepted_tags_enforced_denies_default_zero_tag`
(`test/AcceptedDesign.t.sol`)

Also: `test_tag_allowlist_blocks_untagged`.

## Fix or accepted residual

**Accepted.** Auto-allowing `bytes32(0)` would make “tags on” a no-op for
untagged accounts. The issuer must allow tags before enforcing them. Documented
in `Compliance` natspec.

## Retest

```bash
forge test --match-test test_accepted_tags_enforced_denies_default_zero_tag
```
