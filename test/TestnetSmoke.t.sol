// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Test } from "forge-std/Test.sol";

import { Deploy } from "../script/Deploy.s.sol";
import { TestnetSmoke } from "../script/TestnetSmoke.s.sol";
import { PermissionedToken } from "../src/PermissionedToken.sol";

/// @dev Locks rehearsal tooling. Does not broadcast and does not fork Sepolia.
contract TestnetSmokeTest is Test {
    function test_smoke_refuses_non_sepolia_chain() public {
        TestnetSmoke smoke = new TestnetSmoke();
        vm.expectRevert(abi.encodeWithSelector(TestnetSmoke.WrongChain.selector, block.chainid, uint256(11_155_111)));
        smoke.preflight();
    }

    function test_deploy_public_testnet_labels_are_afpt() public {
        Deploy script = new Deploy();
        address admin = makeAddr("admin");
        (,, address tokenAddr) =
            script.deploy(admin, admin, admin, admin, "Atlas Forge Permissioned Test Token", "AFPT");
        PermissionedToken token = PermissionedToken(tokenAddr);
        assertEq(token.name(), "Atlas Forge Permissioned Test Token");
        assertEq(token.symbol(), "AFPT");
    }
}
