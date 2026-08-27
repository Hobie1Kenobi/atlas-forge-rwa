// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Script, console2 } from "forge-std/Script.sol";

import { IdentityRegistry } from "../src/IdentityRegistry.sol";
import { Compliance } from "../src/Compliance.sol";
import { PermissionedToken } from "../src/PermissionedToken.sol";

/// @title Deploy
/// @notice Local/testnet rehearsal only. Grants DEFAULT_ADMIN to `ADMIN` (or the
/// broadcaster) and optionally the same address as ISSUER / FREEZER / RECOVERY so
/// a single key can exercise the sketch. A production fork should split those
/// roles and put DEFAULT_ADMIN on a timelock — this script does not.
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
        (address registry, address compliance, address token) =
            _deploy(admin, issuer, freezer, recovery, name_, symbol_);
        vm.stopBroadcast();

        console2.log("IdentityRegistry", registry);
        console2.log("Compliance", compliance);
        console2.log("PermissionedToken", token);
        console2.log("DEFAULT_ADMIN", admin);
        console2.log("ISSUER", issuer);
        console2.log("FREEZER", freezer);
        console2.log("RECOVERY", recovery);
        console2.log("Not a live issuance. Addresses above are this broadcast only.");
    }

    function _deploy(
        address admin,
        address issuer,
        address freezer,
        address recovery,
        string memory name_,
        string memory symbol_
    ) internal returns (address registryAddr, address complianceAddr, address tokenAddr) {
        IdentityRegistry registry = new IdentityRegistry(admin);
        Compliance compliance = new Compliance(admin);
        PermissionedToken token = new PermissionedToken(name_, symbol_, admin, registry, compliance);

        registry.grantRole(registry.ISSUER_ROLE(), issuer);
        compliance.grantRole(compliance.ISSUER_ROLE(), issuer);
        token.grantRole(token.ISSUER_ROLE(), issuer);
        token.grantRole(token.FREEZER_ROLE(), freezer);
        token.grantRole(token.RECOVERY_ROLE(), recovery);

        registryAddr = address(registry);
        complianceAddr = address(compliance);
        tokenAddr = address(token);
    }
}
