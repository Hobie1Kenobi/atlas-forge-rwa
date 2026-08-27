// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

import { Fixture } from "./helpers/Fixture.sol";
import { IdentityRegistry } from "../src/IdentityRegistry.sol";

contract IdentityRegistryTest is Fixture {
    function test_issuer_sets_verified_with_attestation_hash() public {
        address newbie = makeAddr("newbie");
        vm.prank(issuer);
        registry.setVerified(newbie, true, DEMO_ATTESTATION);

        assertTrue(registry.isVerified(newbie));
        assertEq(registry.attestationHashOf(newbie), DEMO_ATTESTATION);
    }

    function test_issuer_can_delist_without_clearing_hash() public {
        vm.prank(issuer);
        registry.setVerified(alice, false, DEMO_ATTESTATION);

        assertFalse(registry.isVerified(alice));
        assertEq(registry.attestationHashOf(alice), DEMO_ATTESTATION);
    }

    function test_unauthorized_set_verified_reverts() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, attacker, registry.ISSUER_ROLE()
            )
        );
        vm.prank(attacker);
        registry.setVerified(attacker, true, bytes32(0));
    }

    function test_admin_cannot_set_verified_without_issuer_role() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, admin, registry.ISSUER_ROLE()
            )
        );
        vm.prank(admin);
        registry.setVerified(attacker, true, bytes32(0));
    }

    function test_cannot_verify_zero_address() public {
        vm.expectRevert(IdentityRegistry.ZeroAddress.selector);
        vm.prank(issuer);
        registry.setVerified(address(0), true, DEMO_ATTESTATION);
    }

    function test_constructor_rejects_zero_admin() public {
        vm.expectRevert(IdentityRegistry.ZeroAddress.selector);
        new IdentityRegistry(address(0));
    }

    function test_unlisted_address_is_not_verified() public view {
        assertFalse(registry.isVerified(attacker));
        assertEq(registry.attestationHashOf(attacker), bytes32(0));
    }
}
