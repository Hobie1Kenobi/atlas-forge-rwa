# Sepolia deployment records

**This repository has not been deployed to Sepolia (or any public chain) in this PR.**

`sepolia.example.json` is a schema for a future hand-written record. Do not paste
Foundry `broadcast/` JSON here (`run-latest` can contain private keys). Do not
invent transaction hashes, contract addresses, or explorer URLs.

When a real rehearsal broadcast happens in a later change:

1. Copy `sepolia.example.json` to a gitignored working file (or a sanitized
   committed record with public addresses only).
2. Fill addresses from the deploy script console logs, not from keystore files.
3. Keep `TOKEN_NAME` = `Atlas Forge Permissioned Test Token` and `TOKEN_SYMBOL` =
   `AFPT` on the public testnet path.
4. Leave `broadcastTxHash` empty until a real tx exists. Never fabricate one.

Chain id must be `11155111`.
