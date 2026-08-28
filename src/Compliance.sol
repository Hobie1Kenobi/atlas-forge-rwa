// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

import { ICompliance } from "./interfaces/ICompliance.sol";

/// @title Compliance
/// @author Hobie Cunningham
/// @notice Demo transfer policy: per-address max balance and an optional `bytes32` tag
/// allowlist. Tags are country/class *codes*, not geofencing, not sanctions screening,
/// and not a substitute for a transfer-agent rule engine.
///
/// `maxBalance == 0` means uncapped. `tagsEnforced == false` (default) means tags are
/// stored for demo but not checked. When `tagsEnforced` is turned on, the default
/// `bytes32(0)` tag is denied unless the issuer explicitly `setAllowedTag(0, true)`.
///
/// `ISSUER_ROLE` here is independent of `PermissionedToken.ISSUER_ROLE`.
contract Compliance is AccessControl, ICompliance {
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");

    /// @notice Maximum post-transfer balance per address. Zero = uncapped.
    uint256 public maxBalance;

    /// @notice When true, both parties to a transfer must carry an allowed tag.
    bool public tagsEnforced;

    mapping(bytes32 tag => bool allowed) public allowedTag;
    mapping(address account => bytes32 tag) public tagOf;

    error ZeroAddress();
    error MaxBalanceExceeded(address account, uint256 newBalance, uint256 cap);
    error TagNotAllowed(address account, bytes32 tag);

    event MaxBalanceSet(uint256 previous, uint256 current);
    event TagsEnforcedSet(bool enforced);
    event TagAllowedSet(bytes32 indexed tag, bool allowed);
    event AccountTagSet(address indexed account, bytes32 indexed tag);

    /// @param admin DEFAULT_ADMIN. Cannot be zero.
    /// @param issuer ISSUER_ROLE holder, or address(0) to leave knobs unassigned until
    /// `grantRole`.
    constructor(
        address admin,
        address issuer
    ) {
        if (admin == address(0)) revert ZeroAddress();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        if (issuer != address(0)) _grantRole(ISSUER_ROLE, issuer);
    }

    /// @notice Set the per-address balance cap. Zero disables the cap.
    function setMaxBalance(
        uint256 newMax
    ) external onlyRole(ISSUER_ROLE) {
        uint256 previous = maxBalance;
        maxBalance = newMax;
        emit MaxBalanceSet(previous, newMax);
    }

    /// @notice Turn the demo tag allowlist on or off.
    function setTagsEnforced(
        bool enforced
    ) external onlyRole(ISSUER_ROLE) {
        tagsEnforced = enforced;
        emit TagsEnforcedSet(enforced);
    }

    /// @notice Allow or disallow a demo tag (e.g. keccak256("US-AI") as a class code).
    function setAllowedTag(
        bytes32 tag,
        bool allowed
    ) external onlyRole(ISSUER_ROLE) {
        allowedTag[tag] = allowed;
        emit TagAllowedSet(tag, allowed);
    }

    /// @notice Assign a demo tag to an account. Not PII; not a jurisdiction claim.
    function setTag(
        address account,
        bytes32 tag
    ) external onlyRole(ISSUER_ROLE) {
        if (account == address(0)) revert ZeroAddress();
        tagOf[account] = tag;
        emit AccountTagSet(account, tag);
    }

    /// @inheritdoc ICompliance
    /// @dev Mint (`from == 0`) still checks `to`. Burn (`to == 0`) is a no-op here.
    function validateTransfer(
        address from,
        address to,
        uint256 toBalanceAfter
    ) external view {
        if (to != address(0)) {
            uint256 cap = maxBalance;
            if (cap != 0 && toBalanceAfter > cap) {
                revert MaxBalanceExceeded(to, toBalanceAfter, cap);
            }
            if (tagsEnforced) {
                _requireAllowedTag(to);
            }
        }
        if (from != address(0) && tagsEnforced) {
            _requireAllowedTag(from);
        }
    }

    function _requireAllowedTag(
        address account
    ) internal view {
        bytes32 tag = tagOf[account];
        if (!allowedTag[tag]) revert TagNotAllowed(account, tag);
    }
}
