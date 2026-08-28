// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @title ICompliance
/// @notice Transfer policy: max-balance and optional demo tag allowlist. Not geofencing.
interface ICompliance {
    /// @notice Reverts if `to`'s post-transfer balance or either party's tag fails policy.
    /// @param from Sender, or address(0) on mint.
    /// @param to Recipient, or address(0) on burn.
    /// @param toBalanceAfter Balance of `to` after the movement. Equal to the current
    /// `balanceOf(to)` on self-transfer (amount is not added). Ignored on burn.
    function validateTransfer(
        address from,
        address to,
        uint256 toBalanceAfter
    ) external view;
}
