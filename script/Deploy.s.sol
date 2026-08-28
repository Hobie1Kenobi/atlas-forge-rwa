// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Script, console2 } from "forge-std/Script.sol";

import { IdentityRegistry } from "../src/IdentityRegistry.sol";
import { Compliance } from "../src/Compliance.sol";
import { PermissionedToken } from "../src/PermissionedToken.sol";

/// @title Deploy
/// @notice Local/testnet rehearsal only. Constructors grant DEFAULT_ADMIN and the
/// operational roles, so the broadcaster does **not** need to equal `ADMIN`. A
/// production fork should split those roles and put DEFAULT_ADMIN on a timelock —
/// this script does not.
///
/// Solidity `envOr` fallbacks remain `Atlas Forge Permissioned USD` / `afpUSD` so existing
/// tests that lock those strings stay honest. The **documented public testnet path**
/// sets `TOKEN_NAME` / `TOKEN_SYMBOL` from `.env.example` to
/// `Atlas Forge Permissioned Test Token` / `AFPT`. None of these strings is a USD peg,
/// reserve, redeem, or securities claim.
///
/// This repo is not deployed. Running the script does not make the token a security.
contract Deploy is Script {
    function run() external {
        address admin = vm.envOr("ADMIN", msg.sender);
        address issuer = vm.envOr("ISSUER", admin);
        address freezer = vm.envOr("FREEZER", admin);
        address recovery = vm.envOr("RECOVERY", admin);
        string memory name_ = vm.envOr("TOKEN_NAME", string("Atlas Forge Permissioned USD"));
        string memory symbol_ = vm.envOr("TOKEN_SYMBOL", string("afpUSD"));

        vm.startBroadcast();
        (address registry, address compliance, address token) = deploy(admin, issuer, freezer, recovery, name_, symbol_);
        vm.stopBroadcast();

        console2.log("IdentityRegistry", registry);
        console2.log("Compliance", compliance);
        console2.log("PermissionedToken", token);
        console2.log("DEFAULT_ADMIN", admin);
        console2.log("ISSUER", issuer);
        console2.log("FREEZER", freezer);
        console2.log("RECOVERY", recovery);
        console2.log("Name/symbol are labels, not a USD claim.");
        console2.log("Public rehearsal should set TOKEN_NAME/TOKEN_SYMBOL to AFPT via env.");
        console2.log("Not a live issuance. Addresses above are this broadcast only.");
    }

    /// @notice Deploy the three contracts and grant roles in constructors.
    /// Callable without broadcast so Foundry tests can lock the ADMIN≠broadcaster path.
    function deploy(
        address admin,
        address issuer,
        address freezer,
        address recovery,
        string memory name_,
        string memory symbol_
    ) public returns (address registryAddr, address complianceAddr, address tokenAddr) {
        IdentityRegistry registry = new IdentityRegistry(admin, issuer);
        Compliance compliance = new Compliance(admin, issuer);
        PermissionedToken token =
            new PermissionedToken(name_, symbol_, admin, issuer, freezer, recovery, registry, compliance);

        registryAddr = address(registry);
        complianceAddr = address(compliance);
        tokenAddr = address(token);
    }
}
