// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { IERC20Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

import { Fixture } from "./helpers/Fixture.sol";
import { IdentityRegistry } from "../src/IdentityRegistry.sol";
import { Compliance } from "../src/Compliance.sol";
import { PermissionedToken } from "../src/PermissionedToken.sol";

contract PermissionedTokenTest is Fixture {
    // -------------------------------------------------------------------------
    // Supply invariants: freeze and forceTransfer do not mint/burn
    // -------------------------------------------------------------------------

    function test_freeze_does_not_change_supply_or_balances() public {
        uint256 supply = token.totalSupply();
        uint256 aliceBal = token.balanceOf(alice);

        vm.prank(freezer);
        token.freeze(alice);

        assertEq(token.totalSupply(), supply);
        assertEq(token.balanceOf(alice), aliceBal);
        assertTrue(token.frozen(alice));
    }

    function test_unfreeze_does_not_change_supply() public {
        uint256 supply = token.totalSupply();
        vm.prank(freezer);
        token.freeze(alice);
        vm.prank(freezer);
        token.unfreeze(alice);

        assertEq(token.totalSupply(), supply);
        assertFalse(token.frozen(alice));
    }

    function test_force_transfer_moves_without_changing_supply() public {
        uint256 supply = token.totalSupply();
        uint256 aliceBefore = token.balanceOf(alice);
        uint256 bobBefore = token.balanceOf(bob);

        vm.prank(recovery);
        token.forceTransfer(alice, bob, 100 ether);

        assertEq(token.totalSupply(), supply);
        assertEq(token.balanceOf(alice), aliceBefore - 100 ether);
        assertEq(token.balanceOf(bob), bobBefore + 100 ether);
    }

    function test_issuer_force_transfer_moves_without_changing_supply() public {
        uint256 supply = token.totalSupply();
        vm.prank(issuer);
        token.forceTransfer(alice, bob, 10 ether);
        assertEq(token.totalSupply(), supply);
        assertEq(token.balanceOf(bob), 510 ether);
    }

    function test_only_issuer_mint_and_burn_change_supply() public {
        uint256 supply = token.totalSupply();
        vm.prank(issuer);
        token.mint(charlie, 7 ether);
        assertEq(token.totalSupply(), supply + 7 ether);

        vm.prank(issuer);
        token.burn(charlie, 3 ether);
        assertEq(token.totalSupply(), supply + 4 ether);
    }

    function test_force_transfer_cannot_mint_or_burn() public {
        vm.expectRevert(PermissionedToken.ForceTransferMintOrBurn.selector);
        vm.prank(recovery);
        token.forceTransfer(address(0), bob, 1);

        vm.expectRevert(PermissionedToken.ForceTransferMintOrBurn.selector);
        vm.prank(recovery);
        token.forceTransfer(alice, address(0), 1);
    }

    // -------------------------------------------------------------------------
    // Unverified cannot send or receive except issuer mint and forceTransfer
    // -------------------------------------------------------------------------

    function test_unverified_cannot_receive_transfer() public {
        vm.expectRevert(abi.encodeWithSelector(PermissionedToken.NotVerified.selector, attacker));
        vm.prank(alice);
        token.transfer(attacker, 1 ether);
    }

    function test_unverified_cannot_send_transfer() public {
        vm.prank(recovery);
        token.forceTransfer(alice, attacker, 5 ether);
        assertEq(token.balanceOf(attacker), 5 ether);

        vm.expectRevert(abi.encodeWithSelector(PermissionedToken.NotVerified.selector, attacker));
        vm.prank(attacker);
        token.transfer(bob, 1 ether);
    }

    function test_unverified_cannot_receive_transferFrom() public {
        vm.prank(alice);
        token.approve(bob, 10 ether);

        vm.expectRevert(abi.encodeWithSelector(PermissionedToken.NotVerified.selector, attacker));
        vm.prank(bob);
        token.transferFrom(alice, attacker, 1 ether);
    }

    function test_unverified_cannot_send_transferFrom() public {
        vm.prank(recovery);
        token.forceTransfer(alice, attacker, 5 ether);
        vm.prank(attacker);
        token.approve(bob, 5 ether);

        vm.expectRevert(abi.encodeWithSelector(PermissionedToken.NotVerified.selector, attacker));
        vm.prank(bob);
        token.transferFrom(attacker, alice, 1 ether);
    }

    function test_issuer_mint_to_unverified_succeeds() public {
        vm.prank(issuer);
        token.mint(attacker, 42 ether);
        assertEq(token.balanceOf(attacker), 42 ether);
        assertFalse(registry.isVerified(attacker));
    }

    function test_issuer_burn_from_unverified_succeeds() public {
        vm.prank(issuer);
        token.mint(attacker, 42 ether);
        vm.prank(issuer);
        token.burn(attacker, 10 ether);
        assertEq(token.balanceOf(attacker), 32 ether);
    }

    function test_force_transfer_to_unverified_succeeds() public {
        vm.prank(recovery);
        token.forceTransfer(alice, attacker, 8 ether);
        assertEq(token.balanceOf(attacker), 8 ether);
        assertFalse(registry.isVerified(attacker));
    }

    function test_force_transfer_from_unverified_succeeds() public {
        vm.prank(issuer);
        token.mint(attacker, 8 ether);
        vm.prank(recovery);
        token.forceTransfer(attacker, alice, 8 ether);
        assertEq(token.balanceOf(attacker), 0);
    }

    function test_delisted_holder_cannot_send_or_receive() public {
        vm.prank(issuer);
        registry.setVerified(bob, false, DEMO_ATTESTATION);

        vm.expectRevert(abi.encodeWithSelector(PermissionedToken.NotVerified.selector, bob));
        vm.prank(alice);
        token.transfer(bob, 1);

        vm.expectRevert(abi.encodeWithSelector(PermissionedToken.NotVerified.selector, bob));
        vm.prank(bob);
        token.transfer(alice, 1);
    }

    function test_verified_holders_can_transfer() public {
        vm.prank(alice);
        token.transfer(bob, 25 ether);
        assertEq(token.balanceOf(bob), 525 ether);
        assertEq(token.balanceOf(alice), 975 ether);
    }

    function test_verified_holders_can_transferFrom() public {
        vm.prank(alice);
        token.approve(charlie, 40 ether);
        vm.prank(charlie);
        token.transferFrom(alice, bob, 40 ether);
        assertEq(token.balanceOf(bob), 540 ether);
    }

    // -------------------------------------------------------------------------
    // Frozen cannot send or receive (user path, mint, burn)
    // -------------------------------------------------------------------------

    function test_frozen_cannot_send() public {
        vm.prank(freezer);
        token.freeze(alice);

        vm.expectRevert(abi.encodeWithSelector(PermissionedToken.AccountFrozen.selector, alice));
        vm.prank(alice);
        token.transfer(bob, 1 ether);
    }

    function test_frozen_cannot_receive() public {
        vm.prank(freezer);
        token.freeze(bob);

        vm.expectRevert(abi.encodeWithSelector(PermissionedToken.AccountFrozen.selector, bob));
        vm.prank(alice);
        token.transfer(bob, 1 ether);
    }

    function test_frozen_cannot_send_or_receive_transferFrom() public {
        vm.prank(alice);
        token.approve(charlie, 10 ether);

        vm.prank(freezer);
        token.freeze(alice);
        vm.expectRevert(abi.encodeWithSelector(PermissionedToken.AccountFrozen.selector, alice));
        vm.prank(charlie);
        token.transferFrom(alice, bob, 1 ether);

        vm.prank(freezer);
        token.unfreeze(alice);
        vm.prank(freezer);
        token.freeze(bob);
        vm.expectRevert(abi.encodeWithSelector(PermissionedToken.AccountFrozen.selector, bob));
        vm.prank(charlie);
        token.transferFrom(alice, bob, 1 ether);
    }

    function test_cannot_mint_to_frozen() public {
        vm.prank(freezer);
        token.freeze(charlie);
        vm.expectRevert(abi.encodeWithSelector(PermissionedToken.AccountFrozen.selector, charlie));
        vm.prank(issuer);
        token.mint(charlie, 1 ether);
    }

    function test_cannot_burn_from_frozen() public {
        vm.prank(freezer);
        token.freeze(alice);
        vm.expectRevert(abi.encodeWithSelector(PermissionedToken.AccountFrozen.selector, alice));
        vm.prank(issuer);
        token.burn(alice, 1 ether);
    }

    function test_force_transfer_recovers_from_frozen() public {
        uint256 supply = token.totalSupply();
        vm.prank(freezer);
        token.freeze(alice);

        vm.prank(recovery);
        token.forceTransfer(alice, bob, 100 ether);

        assertEq(token.totalSupply(), supply);
        assertEq(token.balanceOf(alice), 900 ether);
        assertEq(token.balanceOf(bob), 600 ether);
        assertTrue(token.frozen(alice));
    }

    function test_unfreeze_restores_user_transfers() public {
        vm.prank(freezer);
        token.freeze(alice);
        vm.prank(freezer);
        token.unfreeze(alice);

        vm.prank(alice);
        token.transfer(bob, 1 ether);
        assertEq(token.balanceOf(bob), 501 ether);
    }

    // -------------------------------------------------------------------------
    // Only ISSUER mints
    // -------------------------------------------------------------------------

    function test_only_issuer_mints() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, attacker, token.ISSUER_ROLE()
            )
        );
        vm.prank(attacker);
        token.mint(attacker, 1 ether);

        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, admin, token.ISSUER_ROLE())
        );
        vm.prank(admin);
        token.mint(alice, 1 ether);

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, recovery, token.ISSUER_ROLE()
            )
        );
        vm.prank(recovery);
        token.mint(alice, 1 ether);
    }

    function test_only_issuer_burns() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, attacker, token.ISSUER_ROLE()
            )
        );
        vm.prank(attacker);
        token.burn(alice, 1 ether);
    }

    function test_mint_and_burn_reject_zero_amount() public {
        vm.expectRevert(PermissionedToken.ZeroAmount.selector);
        vm.prank(issuer);
        token.mint(alice, 0);

        vm.expectRevert(PermissionedToken.ZeroAmount.selector);
        vm.prank(issuer);
        token.burn(alice, 0);
    }

    // -------------------------------------------------------------------------
    // Unauthorized freeze / forceTransfer / setVerified revert
    // -------------------------------------------------------------------------

    function test_unauthorized_freeze_reverts() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, attacker, token.FREEZER_ROLE()
            )
        );
        vm.prank(attacker);
        token.freeze(alice);

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, issuer, token.FREEZER_ROLE()
            )
        );
        vm.prank(issuer);
        token.freeze(alice);
    }

    function test_unauthorized_unfreeze_reverts() public {
        vm.prank(freezer);
        token.freeze(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, attacker, token.FREEZER_ROLE()
            )
        );
        vm.prank(attacker);
        token.unfreeze(alice);
    }

    function test_unauthorized_force_transfer_reverts() public {
        vm.expectRevert(abi.encodeWithSelector(PermissionedToken.UnauthorizedForceTransfer.selector, attacker));
        vm.prank(attacker);
        token.forceTransfer(alice, bob, 1 ether);

        vm.expectRevert(abi.encodeWithSelector(PermissionedToken.UnauthorizedForceTransfer.selector, freezer));
        vm.prank(freezer);
        token.forceTransfer(alice, bob, 1 ether);

        vm.expectRevert(abi.encodeWithSelector(PermissionedToken.UnauthorizedForceTransfer.selector, admin));
        vm.prank(admin);
        token.forceTransfer(alice, bob, 1 ether);
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

    function test_force_transfer_zero_amount_reverts() public {
        vm.expectRevert(PermissionedToken.ZeroAmount.selector);
        vm.prank(recovery);
        token.forceTransfer(alice, bob, 0);
    }

    function test_force_transfer_insufficient_balance_reverts() public {
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, alice, 1000 ether, 1001 ether)
        );
        vm.prank(recovery);
        token.forceTransfer(alice, bob, 1001 ether);
    }

    function test_freeze_zero_address_reverts() public {
        vm.expectRevert(PermissionedToken.ZeroAddress.selector);
        vm.prank(freezer);
        token.freeze(address(0));
    }

    function test_constructor_rejects_zero_addresses() public {
        vm.expectRevert(PermissionedToken.ZeroAddress.selector);
        new PermissionedToken("x", "y", address(0), issuer, freezer, recovery, registry, compliance);

        vm.expectRevert(PermissionedToken.ZeroAddress.selector);
        new PermissionedToken("x", "y", admin, issuer, freezer, recovery, IdentityRegistry(address(0)), compliance);

        vm.expectRevert(PermissionedToken.ZeroAddress.selector);
        new PermissionedToken("x", "y", admin, issuer, freezer, recovery, registry, Compliance(address(0)));
    }

    function test_constructor_grants_operational_roles() public view {
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(token.hasRole(token.ISSUER_ROLE(), issuer));
        assertTrue(token.hasRole(token.FREEZER_ROLE(), freezer));
        assertTrue(token.hasRole(token.RECOVERY_ROLE(), recovery));
        assertFalse(token.hasRole(token.DEFAULT_ADMIN_ROLE(), address(this)));
    }
}
