// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Test } from "forge-std/Test.sol";

import { Fixture } from "./helpers/Fixture.sol";
import { IdentityRegistry } from "../src/IdentityRegistry.sol";
import { Compliance } from "../src/Compliance.sol";
import { PermissionedToken } from "../src/PermissionedToken.sol";

/// @dev Stateful fuzzer over restriction + recovery: transfer, mint, burn, freeze, forceTransfer.
contract RestrictionHandler is Test {
    PermissionedToken public token;
    IdentityRegistry public registry;
    Compliance public compliance;

    address public issuer;
    address public freezer;
    address public recoveryAgent;

    address[] public actors;

    uint256 public ghostMinted;
    uint256 public ghostBurned;

    constructor(
        PermissionedToken token_,
        IdentityRegistry registry_,
        Compliance compliance_,
        address issuer_,
        address freezer_,
        address recoveryAgent_,
        address[] memory actors_
    ) {
        token = token_;
        registry = registry_;
        compliance = compliance_;
        issuer = issuer_;
        freezer = freezer_;
        recoveryAgent = recoveryAgent_;
        actors = actors_;
        ghostMinted = token_.totalSupply();
    }

    function actor(
        uint256 seed
    ) internal view returns (address) {
        return actors[seed % actors.length];
    }

    function transfer(
        uint256 seedFrom,
        uint256 seedTo,
        uint256 amount
    ) external {
        address from = actor(seedFrom);
        address to = actor(seedTo);
        uint256 bal = token.balanceOf(from);
        if (bal == 0) return;
        amount = bound(amount, 0, bal);

        bool fromVerified = registry.isVerified(from);
        bool toVerified = registry.isVerified(to);
        bool fromFrozen = token.frozen(from);
        bool toFrozen = token.frozen(to);
        uint256 supplyBefore = token.totalSupply();

        vm.prank(from);
        try token.transfer(to, amount) {
            assertTrue(fromVerified, "unverified sent");
            assertTrue(toVerified, "unverified received");
            assertFalse(fromFrozen, "frozen sent");
            assertFalse(toFrozen, "frozen received");
        } catch { }
        assertEq(token.totalSupply(), supplyBefore, "transfer changed supply");
    }

    function transferFrom(
        uint256 seedFrom,
        uint256 seedTo,
        uint256 seedSpender,
        uint256 amount
    ) external {
        address from = actor(seedFrom);
        address to = actor(seedTo);
        address spender = actor(seedSpender);
        uint256 bal = token.balanceOf(from);
        if (bal == 0) return;
        amount = bound(amount, 0, bal);

        vm.prank(from);
        try token.approve(spender, amount) { }
        catch {
            return;
        }

        uint256 supplyBefore = token.totalSupply();
        vm.prank(spender);
        try token.transferFrom(from, to, amount) {
            assertTrue(registry.isVerified(from));
            assertTrue(registry.isVerified(to));
            assertFalse(token.frozen(from));
            assertFalse(token.frozen(to));
        } catch { }
        assertEq(token.totalSupply(), supplyBefore);
    }

    function mint(
        uint256 seedTo,
        uint256 amount
    ) external {
        address to = actor(seedTo);
        amount = bound(amount, 1, 1000 ether);
        if (token.frozen(to)) return;
        uint256 cap = compliance.maxBalance();
        if (cap != 0 && token.balanceOf(to) + amount > cap) return;

        vm.prank(issuer);
        try token.mint(to, amount) {
            ghostMinted += amount;
        } catch { }
    }

    function burn(
        uint256 seedFrom,
        uint256 amount
    ) external {
        address from = actor(seedFrom);
        uint256 bal = token.balanceOf(from);
        if (bal == 0 || token.frozen(from)) return;
        amount = bound(amount, 1, bal);

        vm.prank(issuer);
        try token.burn(from, amount) {
            ghostBurned += amount;
        } catch { }
    }

    function forceTransfer(
        uint256 seedFrom,
        uint256 seedTo,
        uint256 amount
    ) external {
        address from = actor(seedFrom);
        address to = actor(seedTo);
        if (from == to) return;
        uint256 bal = token.balanceOf(from);
        if (bal == 0) return;
        amount = bound(amount, 1, bal);
        uint256 supplyBefore = token.totalSupply();

        vm.prank(recoveryAgent);
        try token.forceTransfer(from, to, amount) { } catch { }
        assertEq(token.totalSupply(), supplyBefore, "forceTransfer changed supply");
    }

    function freezeAccount(
        uint256 seed
    ) external {
        address account = actor(seed);
        uint256 supplyBefore = token.totalSupply();
        vm.prank(freezer);
        try token.freeze(account) { } catch { }
        assertEq(token.totalSupply(), supplyBefore, "freeze changed supply");
    }

    function unfreezeAccount(
        uint256 seed
    ) external {
        address account = actor(seed);
        uint256 supplyBefore = token.totalSupply();
        vm.prank(freezer);
        try token.unfreeze(account) { } catch { }
        assertEq(token.totalSupply(), supplyBefore, "unfreeze changed supply");
    }

    function setVerified(
        uint256 seed,
        bool verified
    ) external {
        address account = actor(seed);
        vm.prank(issuer);
        try registry.setVerified(account, verified, bytes32(uint256(seed))) { } catch { }
    }
}

contract InvariantTest is Fixture {
    RestrictionHandler internal handler;

    function setUp() public override {
        super.setUp();
        address[] memory actors = new address[](4);
        actors[0] = alice;
        actors[1] = bob;
        actors[2] = charlie;
        actors[3] = attacker;
        handler = new RestrictionHandler(token, registry, compliance, issuer, freezer, recovery, actors);

        bytes4[] memory selectors = new bytes4[](8);
        selectors[0] = RestrictionHandler.transfer.selector;
        selectors[1] = RestrictionHandler.transferFrom.selector;
        selectors[2] = RestrictionHandler.mint.selector;
        selectors[3] = RestrictionHandler.burn.selector;
        selectors[4] = RestrictionHandler.forceTransfer.selector;
        selectors[5] = RestrictionHandler.freezeAccount.selector;
        selectors[6] = RestrictionHandler.unfreezeAccount.selector;
        selectors[7] = RestrictionHandler.setVerified.selector;
        targetSelector(FuzzSelector({ addr: address(handler), selectors: selectors }));
        targetContract(address(handler));
        excludeContract(address(token));
        excludeContract(address(registry));
        excludeContract(address(compliance));
    }

    /// @notice `totalSupply` moves only by ISSUER mint/burn. Freeze and forceTransfer are conservative.
    function invariant_supplyMatchesMintBurn() public view {
        assertEq(token.totalSupply(), handler.ghostMinted() - handler.ghostBurned());
    }

    /// @notice ERC-20 conservation: tracked actor balances cannot exceed supply.
    function invariant_actorBalancesBoundBySupply() public view {
        uint256 sum =
            token.balanceOf(alice) + token.balanceOf(bob) + token.balanceOf(charlie) + token.balanceOf(attacker);
        assertLe(sum, token.totalSupply());
    }

    /// @notice Frozen accounts still cannot complete a *user* transfer (probe both directions).
    function invariant_frozenUserTransferReverts() public {
        address[4] memory actors_ = [alice, bob, charlie, attacker];
        for (uint256 i; i < actors_.length; ++i) {
            address account = actors_[i];
            if (!token.frozen(account)) continue;
            if (token.balanceOf(account) == 0) continue;
            address other = account == alice ? bob : alice;
            vm.prank(account);
            try token.transfer(other, 1) {
                revert("frozen sent");
            } catch { }
            if (token.balanceOf(other) == 0) continue;
            vm.prank(other);
            try token.transfer(account, 1) {
                revert("frozen received");
            } catch { }
        }
    }
}
