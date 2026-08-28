// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { Test } from "forge-std/Test.sol";

import { Fixture } from "./helpers/Fixture.sol";
import { Deploy } from "../script/Deploy.s.sol";
import { IdentityRegistry } from "../src/IdentityRegistry.sol";
import { Compliance } from "../src/Compliance.sol";
import { PermissionedToken } from "../src/PermissionedToken.sol";

/// @dev Locks accepted v1 design. These are not vulnerabilities to "fix" in this sketch.
contract AcceptedDesignTest is Fixture {
    function test_accepted_issuer_is_god_mint_burn_freeze_force() public {
        uint256 supply = token.totalSupply();

        vm.prank(issuer);
        token.mint(attacker, 5 ether);
        vm.prank(freezer);
        token.freeze(alice);
        vm.prank(recovery);
        token.forceTransfer(alice, attacker, 20 ether);
        vm.prank(freezer);
        token.unfreeze(alice);
        vm.prank(issuer);
        token.burn(attacker, 5 ether);

        assertEq(token.totalSupply(), supply);
        assertEq(token.balanceOf(attacker), 20 ether);
        assertFalse(registry.isVerified(attacker));
    }

    function test_accepted_mint_to_unverified() public {
        vm.prank(issuer);
        token.mint(attacker, 1 ether);
        assertEq(token.balanceOf(attacker), 1 ether);
        assertFalse(registry.isVerified(attacker));
    }

    function test_accepted_force_transfer_bypasses_freeze_registry_cap_and_tags() public {
        vm.startPrank(issuer);
        compliance.setMaxBalance(50 ether);
        compliance.setAllowedTag(TAG_US_AI, true);
        compliance.setTag(alice, TAG_US_AI);
        compliance.setTagsEnforced(true);
        vm.stopPrank();

        vm.prank(freezer);
        token.freeze(alice);

        uint256 supply = token.totalSupply();
        vm.prank(recovery);
        token.forceTransfer(alice, attacker, 100 ether);

        assertEq(token.totalSupply(), supply);
        assertEq(token.balanceOf(attacker), 100 ether);
        assertTrue(token.frozen(alice));
        assertFalse(registry.isVerified(attacker));
        assertGt(token.balanceOf(attacker), compliance.maxBalance());
    }

    function test_accepted_force_transfer_does_not_spend_allowance() public {
        vm.prank(alice);
        token.approve(bob, 40 ether);
        vm.prank(recovery);
        token.forceTransfer(alice, bob, 10 ether);
        assertEq(token.allowance(alice, bob), 40 ether);
    }

    function test_accepted_default_admin_is_single_address_not_timelock() public view {
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin));
        assertEq(admin.code.length, 0);
        assertFalse(token.hasRole(token.ISSUER_ROLE(), admin));
        assertFalse(token.hasRole(token.FREEZER_ROLE(), admin));
        assertFalse(token.hasRole(token.RECOVERY_ROLE(), admin));
    }

    function test_accepted_deploy_name_afpUSD_is_label_not_usd_claim() public view {
        assertEq(token.name(), "Atlas Forge Permissioned USD");
        assertEq(token.symbol(), "afpUSD");
        assertEq(token.decimals(), 18);
    }

    function test_accepted_unverified_spender_may_transferFrom_between_verified() public {
        vm.prank(alice);
        token.approve(attacker, 15 ether);
        assertFalse(registry.isVerified(attacker));

        vm.prank(attacker);
        token.transferFrom(alice, bob, 15 ether);
        assertEq(token.balanceOf(bob), 515 ether);
    }

    function test_accepted_token_issuer_is_not_automatically_registry_issuer() public {
        address tokenOnlyIssuer = makeAddr("tokenOnlyIssuer");
        bytes32 tokenIssuerRole = token.ISSUER_ROLE();
        bytes32 registryIssuerRole = registry.ISSUER_ROLE();
        vm.prank(admin);
        token.grantRole(tokenIssuerRole, tokenOnlyIssuer);

        assertTrue(token.hasRole(tokenIssuerRole, tokenOnlyIssuer));
        assertFalse(registry.hasRole(registryIssuerRole, tokenOnlyIssuer));
        assertFalse(compliance.hasRole(compliance.ISSUER_ROLE(), tokenOnlyIssuer));

        vm.prank(tokenOnlyIssuer);
        token.mint(alice, 1 ether);

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, tokenOnlyIssuer, registryIssuerRole
            )
        );
        vm.prank(tokenOnlyIssuer);
        registry.setVerified(attacker, true, bytes32(0));
    }

    function test_accepted_tags_enforced_denies_default_zero_tag() public {
        vm.prank(issuer);
        compliance.setTagsEnforced(true);

        vm.expectRevert(abi.encodeWithSelector(Compliance.TagNotAllowed.selector, bob, bytes32(0)));
        vm.prank(alice);
        token.transfer(bob, 1 ether);
    }
}

/// @dev Deploy constructors grant roles even when the deploying contract is not ADMIN.
contract DeployScriptTest is Test {
    function test_deploy_grants_roles_when_caller_is_not_admin() public {
        address admin = makeAddr("scriptAdmin");
        address issuer = makeAddr("scriptIssuer");
        address freezer = makeAddr("scriptFreezer");
        address recovery = makeAddr("scriptRecovery");

        Deploy script = new Deploy();
        (address registryAddr, address complianceAddr, address tokenAddr) =
            script.deploy(admin, issuer, freezer, recovery, "Atlas Forge Permissioned USD", "afpUSD");

        IdentityRegistry registry = IdentityRegistry(registryAddr);
        Compliance compliance = Compliance(complianceAddr);
        PermissionedToken token = PermissionedToken(tokenAddr);

        assertTrue(registry.hasRole(registry.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(compliance.hasRole(compliance.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin));
        assertFalse(registry.hasRole(registry.DEFAULT_ADMIN_ROLE(), address(script)));
        assertFalse(token.hasRole(token.DEFAULT_ADMIN_ROLE(), address(this)));

        assertTrue(registry.hasRole(registry.ISSUER_ROLE(), issuer));
        assertTrue(compliance.hasRole(compliance.ISSUER_ROLE(), issuer));
        assertTrue(token.hasRole(token.ISSUER_ROLE(), issuer));
        assertTrue(token.hasRole(token.FREEZER_ROLE(), freezer));
        assertTrue(token.hasRole(token.RECOVERY_ROLE(), recovery));

        assertEq(token.name(), "Atlas Forge Permissioned USD");
        assertEq(token.symbol(), "afpUSD");
    }

    function test_deploy_default_labels_match_env_example() public {
        Deploy script = new Deploy();
        address admin = makeAddr("admin");
        (,, address tokenAddr) = script.deploy(admin, admin, admin, admin, "Atlas Forge Permissioned USD", "afpUSD");
        PermissionedToken token = PermissionedToken(tokenAddr);
        assertEq(token.name(), "Atlas Forge Permissioned USD");
        assertEq(token.symbol(), "afpUSD");
    }
}
