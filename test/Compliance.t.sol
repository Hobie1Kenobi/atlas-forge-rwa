// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

import { Fixture } from "./helpers/Fixture.sol";
import { Compliance } from "../src/Compliance.sol";

contract ComplianceTest is Fixture {
    function test_max_balance_blocks_receive() public {
        vm.prank(issuer);
        compliance.setMaxBalance(1200 ether);

        vm.prank(alice);
        token.transfer(bob, 100 ether);
        assertEq(token.balanceOf(bob), 600 ether);

        vm.expectRevert(abi.encodeWithSelector(Compliance.MaxBalanceExceeded.selector, bob, 1201 ether, 1200 ether));
        vm.prank(alice);
        token.transfer(bob, 601 ether);
    }

    function test_max_balance_blocks_issuer_mint() public {
        vm.prank(issuer);
        compliance.setMaxBalance(1000 ether);

        vm.expectRevert(abi.encodeWithSelector(Compliance.MaxBalanceExceeded.selector, alice, 1001 ether, 1000 ether));
        vm.prank(issuer);
        token.mint(alice, 1 ether);
    }

    function test_uncapped_when_max_balance_zero() public {
        vm.prank(issuer);
        token.mint(alice, 10_000 ether);
        assertEq(token.balanceOf(alice), 11_000 ether);
    }

    function test_tag_allowlist_blocks_untagged() public {
        vm.startPrank(issuer);
        compliance.setAllowedTag(TAG_US_AI, true);
        compliance.setTag(alice, TAG_US_AI);
        compliance.setTagsEnforced(true);
        vm.stopPrank();

        vm.expectRevert(abi.encodeWithSelector(Compliance.TagNotAllowed.selector, bob, bytes32(0)));
        vm.prank(alice);
        token.transfer(bob, 1 ether);

        vm.prank(issuer);
        compliance.setTag(bob, TAG_US_AI);

        vm.prank(alice);
        token.transfer(bob, 1 ether);
        assertEq(token.balanceOf(bob), 501 ether);
    }

    function test_tag_allowlist_blocks_disallowed_class_code() public {
        vm.startPrank(issuer);
        compliance.setAllowedTag(TAG_US_AI, true);
        compliance.setTag(alice, TAG_US_AI);
        compliance.setTag(bob, TAG_EU_QI);
        compliance.setTagsEnforced(true);
        vm.stopPrank();

        vm.expectRevert(abi.encodeWithSelector(Compliance.TagNotAllowed.selector, bob, TAG_EU_QI));
        vm.prank(alice);
        token.transfer(bob, 1);
    }

    function test_tags_not_checked_until_enforced() public {
        vm.prank(issuer);
        compliance.setTag(alice, TAG_US_AI);

        vm.prank(alice);
        token.transfer(bob, 1 ether);
        assertEq(token.balanceOf(bob), 501 ether);
    }

    function test_unauthorized_set_max_balance_reverts() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, attacker, compliance.ISSUER_ROLE()
            )
        );
        vm.prank(attacker);
        compliance.setMaxBalance(1);
    }

    function test_unauthorized_set_tag_reverts() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, attacker, compliance.ISSUER_ROLE()
            )
        );
        vm.prank(attacker);
        compliance.setTag(alice, TAG_US_AI);
    }

    function test_constructor_rejects_zero_admin() public {
        vm.expectRevert(Compliance.ZeroAddress.selector);
        new Compliance(address(0));
    }

    function test_force_transfer_bypasses_max_balance() public {
        vm.prank(issuer);
        compliance.setMaxBalance(500 ether);

        vm.prank(recovery);
        token.forceTransfer(alice, bob, 100 ether);
        assertEq(token.balanceOf(bob), 600 ether);
    }
}
