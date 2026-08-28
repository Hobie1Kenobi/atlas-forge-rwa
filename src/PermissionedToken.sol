// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

import { IIdentityRegistry } from "./interfaces/IIdentityRegistry.sol";
import { ICompliance } from "./interfaces/ICompliance.sol";

/// @title PermissionedToken
/// @author Hobie Cunningham
/// @notice Permissioned ERC-20: every `transfer` / `transferFrom` / `mint` / `burn` path
/// hits identity + freeze + compliance checks, except the documented issuer exceptions.
///
/// This is portfolio-grade restriction architecture, not securities infrastructure.
/// Freeze, recovery, and issuer mint/burn are **issuer-is-god** — the point of a
/// permissioned RWA token, not a hidden backdoor. See `docs/threat-model.md` and
/// `docs/findings/README.md`.
///
/// Exceptions to the verified-registry check:
/// - ISSUER `mint` (may credit an unverified `to`)
/// - ISSUER `burn` (may debit an unverified `from`)
/// - RECOVERY or ISSUER `forceTransfer` (moves balances; never mints or burns)
///
/// `forceTransfer` calls ERC-20 `_update` directly, so it bypasses freeze, max-balance,
/// and the tag allowlist so a lost-key recovery can land tokens on a replacement wallet.
/// User `transfer` / `transferFrom` never get that bypass. Frozen addresses cannot send
/// or receive on the user path; mint to frozen and burn from frozen also revert.
///
/// v1 uses a single `DEFAULT_ADMIN_ROLE` that grants ISSUER / FREEZER / RECOVERY.
/// A production fork should put DEFAULT_ADMIN on a timelock (atlas-forge-vault
/// already shows the 48h pattern). This sketch does not duplicate that timelock.
///
/// The constructor `name_` / `symbol_` are labels. Default deploy uses `afpUSD`; that is
/// not a USD peg, reserve, redeem, or legal claim.
contract PermissionedToken is ERC20, AccessControl {
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant FREEZER_ROLE = keccak256("FREEZER_ROLE");
    bytes32 public constant RECOVERY_ROLE = keccak256("RECOVERY_ROLE");

    IIdentityRegistry public immutable registry;
    ICompliance public immutable compliance;

    mapping(address account => bool) public frozen;

    error ZeroAddress();
    error ZeroAmount();
    error AccountFrozen(address account);
    error NotVerified(address account);
    error UnauthorizedForceTransfer(address account);
    error ForceTransferMintOrBurn();

    event Frozen(address indexed account);
    event Unfrozen(address indexed account);
    event ForcedTransfer(address indexed from, address indexed to, uint256 amount, address indexed operator);

    constructor(
        string memory name_,
        string memory symbol_,
        address admin_,
        address issuer_,
        address freezer_,
        address recovery_,
        IIdentityRegistry registry_,
        ICompliance compliance_
    ) ERC20(name_, symbol_) {
        if (admin_ == address(0) || address(registry_) == address(0) || address(compliance_) == address(0)) {
            revert ZeroAddress();
        }
        registry = registry_;
        compliance = compliance_;
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        if (issuer_ != address(0)) _grantRole(ISSUER_ROLE, issuer_);
        if (freezer_ != address(0)) _grantRole(FREEZER_ROLE, freezer_);
        if (recovery_ != address(0)) _grantRole(RECOVERY_ROLE, recovery_);
    }

    // -------------------------------------------------------------------------
    // ISSUER supply
    // -------------------------------------------------------------------------

    /// @notice Mint `amount` to `to`. ISSUER-only. Skips the verified-registry check on
    /// `to` (so an issuer can seed a wallet before or after listing). Reverts if `to`
    /// is frozen. Max-balance and tags still apply.
    function mint(
        address to,
        uint256 amount
    ) external onlyRole(ISSUER_ROLE) {
        if (amount == 0) revert ZeroAmount();
        _mint(to, amount);
    }

    /// @notice Burn `amount` from `from`. ISSUER-only. Skips the verified-registry check
    /// on `from`. Reverts if `from` is frozen — unfreeze first, then burn.
    function burn(
        address from,
        uint256 amount
    ) external onlyRole(ISSUER_ROLE) {
        if (amount == 0) revert ZeroAmount();
        _burn(from, amount);
    }

    // -------------------------------------------------------------------------
    // FREEZER
    // -------------------------------------------------------------------------

    /// @notice Freeze `account` so it cannot send or receive on the user path, mint, or
    /// burn. Does not move tokens and does not change `totalSupply`.
    function freeze(
        address account
    ) external onlyRole(FREEZER_ROLE) {
        if (account == address(0)) revert ZeroAddress();
        frozen[account] = true;
        emit Frozen(account);
    }

    /// @notice Clear a freeze. FREEZER-only.
    function unfreeze(
        address account
    ) external onlyRole(FREEZER_ROLE) {
        if (account == address(0)) revert ZeroAddress();
        frozen[account] = false;
        emit Unfrozen(account);
    }

    // -------------------------------------------------------------------------
    // RECOVERY / ISSUER
    // -------------------------------------------------------------------------

    /// @notice Move `amount` from `from` to `to` without minting or burning.
    /// RECOVERY or ISSUER. Bypasses verified, freeze, max-balance, and tags by calling
    /// ERC-20 `_update` directly (no permissioned hook, no storage flag). That bypass
    /// is the recovery tool, not a bug — document it to integrators.
    function forceTransfer(
        address from,
        address to,
        uint256 amount
    ) external {
        address operator = _msgSender();
        if (!hasRole(RECOVERY_ROLE, operator) && !hasRole(ISSUER_ROLE, operator)) {
            revert UnauthorizedForceTransfer(operator);
        }
        if (from == address(0) || to == address(0)) revert ForceTransferMintOrBurn();
        if (amount == 0) revert ZeroAmount();

        super._update(from, to, amount);

        emit ForcedTransfer(from, to, amount, operator);
    }

    // -------------------------------------------------------------------------
    // ERC-20 hook
    // -------------------------------------------------------------------------

    /// @inheritdoc ERC20
    /// @dev `transfer`, `transferFrom`, `mint`, and `burn` all land here. `forceTransfer`
    /// does not — it calls `ERC20._update` via `super`.
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override {
        _checkPermissioned(from, to, value);
        super._update(from, to, value);
    }

    function _checkPermissioned(
        address from,
        address to,
        uint256 value
    ) internal view {
        bool isMint = from == address(0);
        bool isBurn = to == address(0);

        if (!isMint && frozen[from]) revert AccountFrozen(from);
        if (!isBurn && frozen[to]) revert AccountFrozen(to);

        if (!isMint && !isBurn) {
            if (!registry.isVerified(from)) revert NotVerified(from);
            if (!registry.isVerified(to)) revert NotVerified(to);
        }

        if (!isBurn) {
            // Self-transfer does not increase `to`'s balance; do not add `value` or a
            // holder already at `maxBalance` cannot no-op transfer to themselves.
            uint256 toBalanceAfter = from == to ? balanceOf(to) : balanceOf(to) + value;
            compliance.validateTransfer(from, to, toBalanceAfter);
        }
    }
}
