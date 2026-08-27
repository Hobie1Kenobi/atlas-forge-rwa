// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Fixture } from "./helpers/Fixture.sol";
import { PermissionedToken } from "../src/PermissionedToken.sol";
import { Compliance } from "../src/Compliance.sol";

/// @dev Fuzz random transfer attempts against the permissioned checks. No exploit payloads.
contract FuzzTest is Fixture {
    function testFuzz_randomTransferAttempts(
        address from,
        address to,
        uint256 amount
    ) public {
        vm.assume(from != address(0) && to != address(0));
        amount = bound(amount, 0, type(uint128).max);

        uint256 supplyBefore = token.totalSupply();
        vm.prank(from);
        try token.transfer(to, amount) {
            assertFalse(token.frozen(from), "frozen cannot send");
            assertFalse(token.frozen(to), "frozen cannot receive");
            assertTrue(registry.isVerified(from), "unverified cannot send");
            assertTrue(registry.isVerified(to), "unverified cannot receive");
            if (from != to) {
                assertLe(amount, supplyBefore);
            }
            uint256 cap = compliance.maxBalance();
            if (cap != 0) assertLe(token.balanceOf(to), cap);
        } catch { }
        assertEq(token.totalSupply(), supplyBefore, "user transfer must not change supply");
    }

    function testFuzz_randomTransferFromAttempts(
        address spender,
        address from,
        address to,
        uint256 amount
    ) public {
        vm.assume(spender != address(0) && from != address(0) && to != address(0));
        amount = bound(amount, 0, type(uint128).max);

        uint256 supplyBefore = token.totalSupply();
        vm.prank(spender);
        try token.transferFrom(from, to, amount) {
            assertFalse(token.frozen(from));
            assertFalse(token.frozen(to));
            assertTrue(registry.isVerified(from));
            assertTrue(registry.isVerified(to));
        } catch { }
        assertEq(token.totalSupply(), supplyBefore);
    }

    function testFuzz_forceTransferPreservesSupply(
        uint256 amount
    ) public {
        uint256 aliceBal = token.balanceOf(alice);
        amount = bound(amount, 1, aliceBal);
        uint256 supply = token.totalSupply();
        uint256 bobBefore = token.balanceOf(bob);

        vm.prank(recovery);
        token.forceTransfer(alice, bob, amount);

        assertEq(token.totalSupply(), supply);
        assertEq(token.balanceOf(alice) + token.balanceOf(bob), aliceBal + bobBefore);
    }

    function testFuzz_freezeThenUserTransferReverts(
        uint256 amount
    ) public {
        amount = bound(amount, 0, token.balanceOf(alice));
        vm.prank(freezer);
        token.freeze(alice);

        vm.expectRevert(abi.encodeWithSelector(PermissionedToken.AccountFrozen.selector, alice));
        vm.prank(alice);
        token.transfer(bob, amount);
        assertEq(token.totalSupply(), 1500 ether);
    }

    function testFuzz_unverifiedRecipientAlwaysReverts(
        uint256 amount
    ) public {
        amount = bound(amount, 0, token.balanceOf(alice));
        vm.expectRevert(abi.encodeWithSelector(PermissionedToken.NotVerified.selector, attacker));
        vm.prank(alice);
        token.transfer(attacker, amount);
    }

    function testFuzz_mintOnlyChangesSupplyByAmount(
        uint256 amount
    ) public {
        amount = bound(amount, 1, 1_000_000 ether);
        uint256 supply = token.totalSupply();
        vm.prank(issuer);
        token.mint(charlie, amount);
        assertEq(token.totalSupply(), supply + amount);
    }

    function testFuzz_maxBalanceHonoredOnTransfer(
        uint256 cap,
        uint256 amount
    ) public {
        cap = bound(cap, 500 ether, 2000 ether);
        vm.prank(issuer);
        compliance.setMaxBalance(cap);

        uint256 bobBal = token.balanceOf(bob);
        amount = bound(amount, 0, token.balanceOf(alice));

        uint256 supply = token.totalSupply();
        vm.prank(alice);
        if (amount == 0 || bobBal + amount <= cap) {
            token.transfer(bob, amount);
            assertLe(token.balanceOf(bob), cap);
        } else {
            vm.expectRevert(abi.encodeWithSelector(Compliance.MaxBalanceExceeded.selector, bob, bobBal + amount, cap));
            token.transfer(bob, amount);
        }
        assertEq(token.totalSupply(), supply);
    }
}
