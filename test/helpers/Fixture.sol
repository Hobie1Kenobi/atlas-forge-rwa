// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Test } from "forge-std/Test.sol";

import { IdentityRegistry } from "../../src/IdentityRegistry.sol";
import { Compliance } from "../../src/Compliance.sol";
import { PermissionedToken } from "../../src/PermissionedToken.sol";

/// @dev Shared fixture: constructors grant ISSUER / FREEZER / RECOVERY under a single
/// DEFAULT_ADMIN EOA. Alice, Bob, and Charlie are verified holders; attacker is not listed.
abstract contract Fixture is Test {
    IdentityRegistry internal registry;
    Compliance internal compliance;
    PermissionedToken internal token;

    address internal admin = makeAddr("admin");
    address internal issuer = makeAddr("issuer");
    address internal freezer = makeAddr("freezer");
    address internal recovery = makeAddr("recovery");
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");
    address internal charlie = makeAddr("charlie");
    address internal attacker = makeAddr("attacker");

    bytes32 internal constant DEMO_ATTESTATION = keccak256("demo-attestation-not-kyc");
    bytes32 internal constant TAG_US_AI = keccak256("US-AI");
    bytes32 internal constant TAG_EU_QI = keccak256("EU-QI");

    function setUp() public virtual {
        registry = new IdentityRegistry(admin, issuer);
        compliance = new Compliance(admin, issuer);
        token = new PermissionedToken(
            "Atlas Forge Permissioned Test Token", "AFPT", admin, issuer, freezer, recovery, registry, compliance
        );

        vm.startPrank(issuer);
        registry.setVerified(alice, true, DEMO_ATTESTATION);
        registry.setVerified(bob, true, DEMO_ATTESTATION);
        registry.setVerified(charlie, true, DEMO_ATTESTATION);
        token.mint(alice, 1000 ether);
        token.mint(bob, 500 ether);
        vm.stopPrank();
    }

    function _verify(
        address account
    ) internal {
        vm.prank(issuer);
        registry.setVerified(account, true, DEMO_ATTESTATION);
    }
}
