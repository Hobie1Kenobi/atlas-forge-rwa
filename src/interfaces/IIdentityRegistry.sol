// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @title IIdentityRegistry
/// @notice Verified-address registry. `attestationHash` is an off-chain commitment, not PII.
interface IIdentityRegistry {
    /// @notice Whether `account` is marked verified by the issuer.
    function isVerified(
        address account
    ) external view returns (bool);

    /// @notice Last attestation commitment for `account`. Bytes32 hash, never raw KYC data.
    function attestationHashOf(
        address account
    ) external view returns (bytes32);
}
