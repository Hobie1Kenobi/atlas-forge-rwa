// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Script, console2 } from "forge-std/Script.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

import { IdentityRegistry } from "../src/IdentityRegistry.sol";
import { Compliance } from "../src/Compliance.sol";
import { PermissionedToken } from "../src/PermissionedToken.sol";

/// @title TestnetSmoke
/// @notice Public Sepolia rehearsal against **already deployed** addresses.
/// Does not deploy. Does not mock chain state. Refuses any chain id other than
/// 11155111. This PR does not broadcast; operators run `--broadcast` later.
///
/// Sign with a Foundry keystore (`--account atlas-deployer`). Do not pass
/// `--private-key`. Attestation hashes are non-PII test commitments only.
contract TestnetSmoke is Script {
    uint256 public constant SEPOLIA_CHAIN_ID = 11_155_111;

    bytes32 public constant ATTESTATION_ALICE = keccak256("ATLAS_TEST_ATTESTATION_ALICE_V1");
    bytes32 public constant ATTESTATION_BOB = keccak256("ATLAS_TEST_ATTESTATION_BOB_V1");
    bytes32 public constant TEST_POLICY_TAG = keccak256("ATLAS_TEST_POLICY_TAG_A");

    uint256 internal constant MINT_AMOUNT = 1000 ether;
    uint256 internal constant TRANSFER_AMOUNT = 100 ether;
    uint256 internal constant TINY_TRANSFER = 1 ether;

    error WrongChain(uint256 got, uint256 expected);
    error MissingCode(string label);
    error ZeroConfiguredAddress(string label);
    error RoleOverlapNotAcknowledged();
    error HolderAddressesMustBeDistinct();
    error UnauthorizedMustNotHoldRoles();
    error ExpectedRevertDidNotOccur(string testName);
    error UnexpectedRevertSelector(string testName, bytes data);

    struct Cfg {
        address admin;
        address issuer;
        address freezer;
        address recovery;
        address alice;
        address bob;
        address charlie;
        address unauthorized;
        PermissionedToken token;
        IdentityRegistry registry;
        Compliance compliance;
        bool ackRoleOverlap;
    }

    /// @notice View/sim checks only. Safe without `--broadcast`.
    function preflight() public {
        Cfg memory cfg = _load();
        _logBanner(cfg, msg.sender);
        _checkRoles(cfg);
        _simulateUnauthorizedReverts(cfg);
        console2.log("PREFLIGHT complete (no broadcast in this function).");
    }

    /// @notice Execute every step the broadcaster can sign. Stage the rest.
    function run() external {
        _runMatrix(msg.sender);
    }

    function stepSetVerified() external {
        Cfg memory cfg = _load();
        vm.startBroadcast();
        _stepSetVerified(cfg, msg.sender);
        vm.stopBroadcast();
    }

    function stepMint() external {
        Cfg memory cfg = _load();
        vm.startBroadcast();
        _stepMint(cfg, msg.sender);
        vm.stopBroadcast();
    }

    function stepAliceToBob() external {
        Cfg memory cfg = _load();
        vm.startBroadcast();
        _stepAliceToBob(cfg, msg.sender);
        vm.stopBroadcast();
    }

    function stepUnauthorizedReverts() external {
        Cfg memory cfg = _load();
        vm.startBroadcast();
        _stepUnauthorizedBroadcast(cfg, msg.sender);
        vm.stopBroadcast();
    }

    function stepUnverifiedTransfers() external {
        Cfg memory cfg = _load();
        vm.startBroadcast();
        _stepUnverifiedTransfers(cfg, msg.sender);
        vm.stopBroadcast();
    }

    function stepFreeze() external {
        Cfg memory cfg = _load();
        vm.startBroadcast();
        _stepFreeze(cfg, msg.sender);
        vm.stopBroadcast();
    }

    function stepFrozenTransfers() external {
        Cfg memory cfg = _load();
        vm.startBroadcast();
        _stepFrozenTransfers(cfg, msg.sender);
        vm.stopBroadcast();
    }

    function stepUnfreeze() external {
        Cfg memory cfg = _load();
        vm.startBroadcast();
        _stepUnfreeze(cfg, msg.sender);
        vm.stopBroadcast();
    }

    function stepForceTransfer() external {
        Cfg memory cfg = _load();
        vm.startBroadcast();
        _stepForceTransfer(cfg, msg.sender);
        vm.stopBroadcast();
    }

    function stepCompliance() external {
        Cfg memory cfg = _load();
        vm.startBroadcast();
        _stepCompliance(cfg, msg.sender);
        vm.stopBroadcast();
    }

    function stepBurn() external {
        Cfg memory cfg = _load();
        vm.startBroadcast();
        _stepBurn(cfg, msg.sender);
        vm.stopBroadcast();
    }

    function _runMatrix(
        address broadcaster
    ) internal {
        Cfg memory cfg = _load();
        _logBanner(cfg, broadcaster);
        _checkRoles(cfg);
        _simulateUnauthorizedReverts(cfg);

        vm.startBroadcast();
        _stepUnauthorizedBroadcast(cfg, broadcaster);
        _stepSetVerified(cfg, broadcaster);
        _stepMint(cfg, broadcaster);
        _stepAliceToBob(cfg, broadcaster);
        _stepUnverifiedTransfers(cfg, broadcaster);
        _stepFreeze(cfg, broadcaster);
        _stepFrozenTransfers(cfg, broadcaster);
        _stepUnfreeze(cfg, broadcaster);
        _stepAliceToBobAfterUnfreeze(cfg, broadcaster);
        _stepFreeze(cfg, broadcaster);
        _stepForceTransfer(cfg, broadcaster);
        _stepCompliance(cfg, broadcaster);
        _stepBurn(cfg, broadcaster);
        vm.stopBroadcast();

        _logSupplyLedger(cfg);
        console2.log("SMOKE matrix finished for this broadcaster.");
        console2.log("Staged steps that were skipped must be re-run with the matching --account.");
    }

    function _load() internal view returns (Cfg memory cfg) {
        if (block.chainid != SEPOLIA_CHAIN_ID) {
            revert WrongChain(block.chainid, SEPOLIA_CHAIN_ID);
        }

        cfg.admin = _requireAddr("ADMIN");
        cfg.issuer = _requireAddr("ISSUER");
        cfg.freezer = _requireAddr("FREEZER");
        cfg.recovery = _requireAddr("RECOVERY");
        cfg.alice = _requireAddr("ALICE");
        cfg.bob = _requireAddr("BOB");
        cfg.charlie = _requireAddr("CHARLIE");
        cfg.unauthorized = _requireAddr("UNAUTHORIZED");
        address tokenAddr = _requireAddr("TOKEN");
        address registryAddr = _requireAddr("REGISTRY");
        address complianceAddr = _requireAddr("COMPLIANCE");
        cfg.ackRoleOverlap = vm.envOr("ACK_ROLE_OVERLAP", false);

        _requireCode(tokenAddr, "TOKEN");
        _requireCode(registryAddr, "REGISTRY");
        _requireCode(complianceAddr, "COMPLIANCE");

        cfg.token = PermissionedToken(tokenAddr);
        cfg.registry = IdentityRegistry(registryAddr);
        cfg.compliance = Compliance(complianceAddr);

        _checkOverlap(cfg);
    }

    function _requireAddr(
        string memory key
    ) internal view returns (address addr) {
        addr = vm.envAddress(key);
        if (addr == address(0)) revert ZeroConfiguredAddress(key);
    }

    function _requireCode(
        address addr,
        string memory label
    ) internal view {
        if (addr.code.length == 0) revert MissingCode(label);
    }

    function _checkOverlap(
        Cfg memory cfg
    ) internal pure {
        if (cfg.alice == cfg.bob || cfg.alice == cfg.charlie || cfg.bob == cfg.charlie) {
            revert HolderAddressesMustBeDistinct();
        }

        bool privilegedOverlap = cfg.admin == cfg.issuer || cfg.admin == cfg.freezer || cfg.admin == cfg.recovery
            || cfg.issuer == cfg.freezer || cfg.issuer == cfg.recovery || cfg.freezer == cfg.recovery;
        if (privilegedOverlap && !cfg.ackRoleOverlap) {
            revert RoleOverlapNotAcknowledged();
        }

        if (
            cfg.unauthorized == cfg.admin || cfg.unauthorized == cfg.issuer || cfg.unauthorized == cfg.freezer
                || cfg.unauthorized == cfg.recovery
        ) {
            revert UnauthorizedMustNotHoldRoles();
        }
    }

    function _logBanner(
        Cfg memory cfg,
        address broadcaster
    ) internal view {
        console2.log("ATLAS FORGE RWA PUBLIC TESTNET ENGINEERING REHEARSAL");
        console2.log("Not a live security, USD-backed asset, audit, KYC platform, or issuance.");
        console2.log("chainId", block.chainid);
        console2.log("broadcaster", broadcaster);
        console2.log("TOKEN", address(cfg.token));
        console2.log("REGISTRY", address(cfg.registry));
        console2.log("COMPLIANCE", address(cfg.compliance));
        console2.log("name", cfg.token.name());
        console2.log("symbol", cfg.token.symbol());
        if (cfg.ackRoleOverlap) {
            console2.log("LIMITATION: ACK_ROLE_OVERLAP=true - privileged roles share keys (faucet/ops).");
            console2.log("This is not production role separation.");
        }
        console2.log("Attestations are keccak256 test strings, never PII.");
    }

    function _checkRoles(
        Cfg memory cfg
    ) internal view {
        if (!cfg.token.hasRole(cfg.token.DEFAULT_ADMIN_ROLE(), cfg.admin)) {
            revert("ROLE_ADMIN mismatch");
        }
        if (!cfg.token.hasRole(cfg.token.ISSUER_ROLE(), cfg.issuer)) {
            revert("ROLE_ISSUER mismatch");
        }
        if (!cfg.token.hasRole(cfg.token.FREEZER_ROLE(), cfg.freezer)) {
            revert("ROLE_FREEZER mismatch");
        }
        if (!cfg.token.hasRole(cfg.token.RECOVERY_ROLE(), cfg.recovery)) {
            revert("ROLE_RECOVERY mismatch");
        }
        if (!cfg.registry.hasRole(cfg.registry.ISSUER_ROLE(), cfg.issuer)) {
            revert("REGISTRY ISSUER mismatch");
        }
        if (!cfg.compliance.hasRole(cfg.compliance.ISSUER_ROLE(), cfg.issuer)) {
            revert("COMPLIANCE ISSUER mismatch");
        }
        if (
            cfg.token.hasRole(cfg.token.ISSUER_ROLE(), cfg.unauthorized)
                || cfg.token.hasRole(cfg.token.FREEZER_ROLE(), cfg.unauthorized)
                || cfg.token.hasRole(cfg.token.RECOVERY_ROLE(), cfg.unauthorized)
                || cfg.token.hasRole(cfg.token.DEFAULT_ADMIN_ROLE(), cfg.unauthorized)
                || cfg.registry.hasRole(cfg.registry.ISSUER_ROLE(), cfg.unauthorized)
                || cfg.compliance.hasRole(cfg.compliance.ISSUER_ROLE(), cfg.unauthorized)
        ) {
            revert UnauthorizedMustNotHoldRoles();
        }
        console2.log("PASS: ROLE_CHECKS");
    }

    /// @dev eth_call simulation against live addresses. Not a mocked chain.
    function _simulateUnauthorizedReverts(
        Cfg memory cfg
    ) internal {
        vm.startPrank(cfg.unauthorized);
        _expectRevertSelector(
            address(cfg.token),
            abi.encodeCall(cfg.token.mint, (cfg.alice, 1)),
            IAccessControl.AccessControlUnauthorizedAccount.selector,
            "UNAUTHORIZED_MINT_REVERT (simulated)"
        );
        _expectRevertSelector(
            address(cfg.token),
            abi.encodeCall(cfg.token.freeze, (cfg.alice)),
            IAccessControl.AccessControlUnauthorizedAccount.selector,
            "UNAUTHORIZED_FREEZE_REVERT (simulated)"
        );
        _expectRevertSelector(
            address(cfg.registry),
            abi.encodeCall(cfg.registry.setVerified, (cfg.alice, true, ATTESTATION_ALICE)),
            IAccessControl.AccessControlUnauthorizedAccount.selector,
            "UNAUTHORIZED_SET_VERIFIED_REVERT (simulated)"
        );
        _expectRevertSelector(
            address(cfg.token),
            abi.encodeCall(cfg.token.forceTransfer, (cfg.alice, cfg.bob, 1)),
            PermissionedToken.UnauthorizedForceTransfer.selector,
            "UNAUTHORIZED_FORCE_TRANSFER_REVERT (simulated)"
        );
        _expectRevertSelector(
            address(cfg.token),
            abi.encodeCall(cfg.token.burn, (cfg.alice, 1)),
            IAccessControl.AccessControlUnauthorizedAccount.selector,
            "UNAUTHORIZED_BURN_REVERT (simulated)"
        );
        vm.stopPrank();
    }

    function _stepUnauthorizedBroadcast(
        Cfg memory cfg,
        address broadcaster
    ) internal {
        if (broadcaster != cfg.unauthorized) {
            console2.log("STAGE: UNAUTHORIZED_* broadcast - re-run --account as UNAUTHORIZED");
            return;
        }
        _expectRevertSelector(
            address(cfg.token),
            abi.encodeCall(cfg.token.mint, (cfg.alice, 1)),
            IAccessControl.AccessControlUnauthorizedAccount.selector,
            "UNAUTHORIZED_MINT_REVERT"
        );
        _expectRevertSelector(
            address(cfg.token),
            abi.encodeCall(cfg.token.freeze, (cfg.alice)),
            IAccessControl.AccessControlUnauthorizedAccount.selector,
            "UNAUTHORIZED_FREEZE_REVERT"
        );
        _expectRevertSelector(
            address(cfg.registry),
            abi.encodeCall(cfg.registry.setVerified, (cfg.alice, true, ATTESTATION_ALICE)),
            IAccessControl.AccessControlUnauthorizedAccount.selector,
            "UNAUTHORIZED_SET_VERIFIED_REVERT"
        );
        _expectRevertSelector(
            address(cfg.token),
            abi.encodeCall(cfg.token.forceTransfer, (cfg.alice, cfg.bob, 1)),
            PermissionedToken.UnauthorizedForceTransfer.selector,
            "UNAUTHORIZED_FORCE_TRANSFER_REVERT"
        );
        _expectRevertSelector(
            address(cfg.token),
            abi.encodeCall(cfg.token.burn, (cfg.alice, 1)),
            IAccessControl.AccessControlUnauthorizedAccount.selector,
            "UNAUTHORIZED_BURN_REVERT"
        );
    }

    function _stepSetVerified(
        Cfg memory cfg,
        address broadcaster
    ) internal {
        if (broadcaster != cfg.issuer) {
            console2.log("STAGE: IDENTITY_SET_VERIFIED - re-run --account as ISSUER");
            return;
        }
        if (cfg.registry.isVerified(cfg.alice)) {
            console2.log("IDENTITY_ALICE already verified (idempotent skip of false-check)");
        } else {
            console2.log("PASS: IDENTITY_ALICE_UNVERIFIED");
        }
        if (cfg.registry.isVerified(cfg.bob)) {
            console2.log("IDENTITY_BOB already verified (idempotent skip of false-check)");
        } else {
            console2.log("PASS: IDENTITY_BOB_UNVERIFIED");
        }
        cfg.registry.setVerified(cfg.alice, true, ATTESTATION_ALICE);
        cfg.registry.setVerified(cfg.bob, true, ATTESTATION_BOB);
        if (!cfg.registry.isVerified(cfg.alice) || cfg.registry.attestationHashOf(cfg.alice) != ATTESTATION_ALICE) {
            revert("IDENTITY_SET_VERIFIED_ALICE failed");
        }
        if (!cfg.registry.isVerified(cfg.bob) || cfg.registry.attestationHashOf(cfg.bob) != ATTESTATION_BOB) {
            revert("IDENTITY_SET_VERIFIED_BOB failed");
        }
        console2.log("PASS: IDENTITY_SET_VERIFIED_ALICE");
        console2.log("PASS: IDENTITY_SET_VERIFIED_BOB");
        console2.log("CHARLIE remains unverified by design.");
    }

    function _stepMint(
        Cfg memory cfg,
        address broadcaster
    ) internal {
        if (broadcaster != cfg.issuer) {
            console2.log("STAGE: MINT_ALICE_1000 - re-run --account as ISSUER");
            return;
        }
        uint256 supplyBefore = cfg.token.totalSupply();
        uint256 aliceBefore = cfg.token.balanceOf(cfg.alice);
        cfg.token.mint(cfg.alice, MINT_AMOUNT);
        if (cfg.token.totalSupply() != supplyBefore + MINT_AMOUNT) revert("MINT_SUPPLY_DELTA failed");
        if (cfg.token.balanceOf(cfg.alice) != aliceBefore + MINT_AMOUNT) revert("MINT_ALICE_1000 failed");
        console2.log("PASS: MINT_ALICE_1000");
        console2.log("PASS: MINT_SUPPLY_DELTA");
        console2.log("totalSupply", cfg.token.totalSupply());
    }

    function _stepAliceToBob(
        Cfg memory cfg,
        address broadcaster
    ) internal {
        if (broadcaster != cfg.alice) {
            console2.log("STAGE: TRANSFER_VERIFIED_ALICE_BOB_100 - re-run --account as ALICE");
            return;
        }
        uint256 supply = cfg.token.totalSupply();
        uint256 aliceBefore = cfg.token.balanceOf(cfg.alice);
        uint256 bobBefore = cfg.token.balanceOf(cfg.bob);
        cfg.token.transfer(cfg.bob, TRANSFER_AMOUNT);
        if (cfg.token.totalSupply() != supply) revert("TRANSFER_SUPPLY_CONSTANT failed");
        if (cfg.token.balanceOf(cfg.alice) != aliceBefore - TRANSFER_AMOUNT) revert("ALICE delta failed");
        if (cfg.token.balanceOf(cfg.bob) != bobBefore + TRANSFER_AMOUNT) revert("BOB delta failed");
        console2.log("PASS: TRANSFER_VERIFIED_ALICE_BOB_100");
        console2.log("PASS: TRANSFER_SUPPLY_CONSTANT");
    }

    function _stepAliceToBobAfterUnfreeze(
        Cfg memory cfg,
        address broadcaster
    ) internal {
        if (broadcaster != cfg.alice) {
            console2.log("STAGE: TRANSFER_AFTER_UNFREEZE - re-run --account as ALICE");
            return;
        }
        uint256 supply = cfg.token.totalSupply();
        cfg.token.transfer(cfg.bob, TINY_TRANSFER);
        if (cfg.token.totalSupply() != supply) revert("TRANSFER_AFTER_UNFREEZE supply changed");
        console2.log("PASS: TRANSFER_AFTER_UNFREEZE");
    }

    function _stepUnverifiedTransfers(
        Cfg memory cfg,
        address broadcaster
    ) internal {
        if (broadcaster == cfg.alice) {
            _expectRevertSelector(
                address(cfg.token),
                abi.encodeCall(cfg.token.transfer, (cfg.charlie, TINY_TRANSFER)),
                PermissionedToken.NotVerified.selector,
                "TRANSFER_UNVERIFIED_ALICE_CHARLIE_REVERT"
            );
        } else {
            console2.log("STAGE: TRANSFER_UNVERIFIED_ALICE_CHARLIE_REVERT - re-run --account as ALICE");
        }
        if (broadcaster == cfg.charlie) {
            _expectRevertSelector(
                address(cfg.token),
                abi.encodeCall(cfg.token.transfer, (cfg.alice, TINY_TRANSFER)),
                PermissionedToken.NotVerified.selector,
                "TRANSFER_UNVERIFIED_CHARLIE_ALICE_REVERT"
            );
        } else {
            console2.log("STAGE: TRANSFER_UNVERIFIED_CHARLIE_ALICE_REVERT - re-run --account as CHARLIE");
        }
    }

    function _stepFreeze(
        Cfg memory cfg,
        address broadcaster
    ) internal {
        if (broadcaster != cfg.freezer) {
            console2.log("STAGE: FREEZE_ALICE - re-run --account as FREEZER");
            return;
        }
        uint256 supply = cfg.token.totalSupply();
        uint256 aliceBal = cfg.token.balanceOf(cfg.alice);
        cfg.token.freeze(cfg.alice);
        if (!cfg.token.frozen(cfg.alice)) revert("FREEZE_ALICE failed");
        if (cfg.token.totalSupply() != supply) revert("freeze changed supply");
        if (cfg.token.balanceOf(cfg.alice) != aliceBal) revert("freeze changed balance");
        console2.log("PASS: FREEZE_ALICE");
    }

    function _stepFrozenTransfers(
        Cfg memory cfg,
        address broadcaster
    ) internal {
        if (broadcaster == cfg.alice) {
            _expectRevertSelector(
                address(cfg.token),
                abi.encodeCall(cfg.token.transfer, (cfg.bob, TINY_TRANSFER)),
                PermissionedToken.AccountFrozen.selector,
                "FROZEN_ALICE_TO_BOB_REVERT"
            );
        } else {
            console2.log("STAGE: FROZEN_ALICE_TO_BOB_REVERT - re-run --account as ALICE");
        }
        if (broadcaster == cfg.bob) {
            _expectRevertSelector(
                address(cfg.token),
                abi.encodeCall(cfg.token.transfer, (cfg.alice, TINY_TRANSFER)),
                PermissionedToken.AccountFrozen.selector,
                "FROZEN_BOB_TO_ALICE_REVERT"
            );
        } else {
            console2.log("STAGE: FROZEN_BOB_TO_ALICE_REVERT - re-run --account as BOB");
        }
    }

    function _stepUnfreeze(
        Cfg memory cfg,
        address broadcaster
    ) internal {
        if (broadcaster != cfg.freezer) {
            console2.log("STAGE: UNFREEZE_ALICE - re-run --account as FREEZER");
            return;
        }
        uint256 supply = cfg.token.totalSupply();
        cfg.token.unfreeze(cfg.alice);
        if (cfg.token.frozen(cfg.alice)) revert("UNFREEZE_ALICE failed");
        if (cfg.token.totalSupply() != supply) revert("unfreeze changed supply");
        console2.log("PASS: UNFREEZE_ALICE");
    }

    /// @dev Admin recovery: from frozen ALICE to unverified UNAUTHORIZED. Supply constant.
    function _stepForceTransfer(
        Cfg memory cfg,
        address broadcaster
    ) internal {
        if (broadcaster != cfg.recovery && broadcaster != cfg.issuer) {
            console2.log("STAGE: FORCE_TRANSFER_FROZEN_ALICE_TO_REPLACEMENT - re-run --account as RECOVERY or ISSUER");
            return;
        }
        if (!cfg.token.frozen(cfg.alice)) {
            console2.log("NOTE: ALICE not frozen; freeze first for the documented recovery path.");
        }
        uint256 amount = cfg.token.balanceOf(cfg.alice);
        if (amount == 0) {
            console2.log("STAGE SKIPPED: FORCE_TRANSFER - ALICE balance is 0");
            return;
        }
        uint256 supply = cfg.token.totalSupply();
        uint256 toBefore = cfg.token.balanceOf(cfg.unauthorized);
        cfg.token.forceTransfer(cfg.alice, cfg.unauthorized, amount);
        if (cfg.token.totalSupply() != supply) revert("FORCE_TRANSFER_SUPPLY_CONSTANT failed");
        if (cfg.token.balanceOf(cfg.alice) != 0) revert("forceTransfer did not debit ALICE");
        if (cfg.token.balanceOf(cfg.unauthorized) != toBefore + amount) {
            revert("forceTransfer did not credit replacement");
        }
        console2.log("PASS: FORCE_TRANSFER_FROZEN_ALICE_TO_REPLACEMENT (admin recovery bypass)");
        console2.log("PASS: FORCE_TRANSFER_SUPPLY_CONSTANT");
        console2.log("Replacement UNAUTHORIZED may be unverified; that is AFR-06, not a bug.");
    }

    function _stepCompliance(
        Cfg memory cfg,
        address broadcaster
    ) internal {
        if (broadcaster != cfg.issuer) {
            console2.log("STAGE: COMPLIANCE_* - re-run --account as ISSUER");
            return;
        }

        // Issuer mint path: skips verified-registry, still honors maxBalance and freeze.
        address probe = cfg.charlie;
        if (cfg.token.frozen(probe)) revert("CHARLIE unexpectedly frozen");
        uint256 probeBal = cfg.token.balanceOf(probe);
        uint256 cap = probeBal + 10 ether;
        cfg.compliance.setMaxBalance(cap);

        uint256 mintOk = 1 ether;
        uint256 supply = cfg.token.totalSupply();
        cfg.token.mint(probe, mintOk);
        if (cfg.token.balanceOf(probe) > cap) revert("below-cap mint exceeded cap");
        if (cfg.token.totalSupply() != supply + mintOk) revert("below-cap mint supply");
        console2.log("PASS: COMPLIANCE_MAX_BALANCE_BELOW_CAP");

        _expectRevertSelector(
            address(cfg.token),
            abi.encodeCall(cfg.token.mint, (probe, 10_000 ether)),
            Compliance.MaxBalanceExceeded.selector,
            "COMPLIANCE_MAX_BALANCE_OVER_CAP_REVERT"
        );

        cfg.compliance.setMaxBalance(0);

        // Test policy codes only - not country, sanctions, or accreditation.
        cfg.compliance.setAllowedTag(TEST_POLICY_TAG, true);
        cfg.compliance.setTag(cfg.bob, TEST_POLICY_TAG);
        cfg.compliance.setTagsEnforced(true);
        if (!cfg.token.frozen(cfg.bob)) {
            uint256 taggedSupply = cfg.token.totalSupply();
            cfg.token.mint(cfg.bob, mintOk);
            if (cfg.token.totalSupply() != taggedSupply + mintOk) revert("tagged mint supply");
        }
        _expectRevertSelector(
            address(cfg.token),
            abi.encodeCall(cfg.token.mint, (cfg.charlie, mintOk)),
            Compliance.TagNotAllowed.selector,
            "TAG_ALLOWLIST_TEST_POLICY"
        );
        cfg.compliance.setTagsEnforced(false);
        console2.log("Tags are ATLAS_TEST_POLICY_* codes only - not country, sanctions, or accreditation.");
    }

    function _stepBurn(
        Cfg memory cfg,
        address broadcaster
    ) internal {
        if (broadcaster != cfg.issuer) {
            console2.log("STAGE: ISSUER_BURN - re-run --account as ISSUER");
            return;
        }
        address target = cfg.token.balanceOf(cfg.bob) > 0 ? cfg.bob : cfg.alice;
        if (cfg.token.frozen(target)) {
            console2.log("NOTE: unfreeze required before issuer burn (source behavior).");
            return;
        }
        uint256 bal = cfg.token.balanceOf(target);
        if (bal == 0) {
            console2.log("STAGE SKIPPED: ISSUER_BURN - no balance");
            return;
        }
        uint256 amount = bal < TINY_TRANSFER ? bal : TINY_TRANSFER;
        uint256 supply = cfg.token.totalSupply();
        cfg.token.burn(target, amount);
        if (cfg.token.totalSupply() != supply - amount) revert("ISSUER_BURN supply delta failed");
        console2.log("PASS: ISSUER_BURN");
    }

    function _logSupplyLedger(
        Cfg memory cfg
    ) internal view {
        console2.log("SUPPLY_LEDGER snapshot (local to this run; fill artifacts/supply-ledger after broadcast)");
        console2.log("totalSupply", cfg.token.totalSupply());
        console2.log("ALICE", cfg.token.balanceOf(cfg.alice));
        console2.log("BOB", cfg.token.balanceOf(cfg.bob));
        console2.log("CHARLIE", cfg.token.balanceOf(cfg.charlie));
        console2.log("UNAUTHORIZED", cfg.token.balanceOf(cfg.unauthorized));
        console2.log("PASS marker for later evidence: SUPPLY_LEDGER_MATCH (NOT EXECUTED on-chain in this PR)");
    }

    function _expectRevertSelector(
        address to,
        bytes memory data,
        bytes4 expectedSel,
        string memory testName
    ) internal {
        (bool success, bytes memory ret) = to.call(data);
        if (success) revert ExpectedRevertDidNotOccur(testName);
        if (ret.length < 4 || bytes4(ret) != expectedSel) {
            revert UnexpectedRevertSelector(testName, ret);
        }
        console2.log("PASS:", testName);
    }
}
