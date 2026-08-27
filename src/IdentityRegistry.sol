// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

import { IIdentityRegistry } from "./interfaces/IIdentityRegistry.sol";

/// @title IdentityRegistry
/// @author Hobie Cunningham
/// @notice ISSUER-managed verified-address set with an optional `bytes32` attestation
/// commitment. This is not a KYC vendor, not ONCHAINID, and not ERC-3643.
///
/// `attestationHash` is a hash of whatever the issuer stored off-chain. Putting PII
/// on-chain would be malpractice; this contract refuses that shape by only accepting
/// `bytes32`.
contract IdentityRegistry is AccessControl, IIdentityRegistry {
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");

    struct Identity {
        bool verified;
        bytes32 attestationHash;
    }

    mapping(address account => Identity) private _identities;

    error ZeroAddress();

    event VerifiedSet(address indexed account, bool verified, bytes32 attestationHash);

    constructor(
        address admin
    ) {
        if (admin == address(0)) revert ZeroAddress();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /// @notice Mark `account` verified or not. ISSUER-only.
    /// @param account Wallet to list or delist. Cannot be address(0).
    /// @param verified Whether the account may participate in user transfers.
    /// @param attestationHash Off-chain attestation commitment. Zero is allowed (no hash).
    function setVerified(
        address account,
        bool verified,
        bytes32 attestationHash
    ) external onlyRole(ISSUER_ROLE) {
        if (account == address(0)) revert ZeroAddress();
        _identities[account] = Identity({ verified: verified, attestationHash: attestationHash });
        emit VerifiedSet(account, verified, attestationHash);
    }

    /// @inheritdoc IIdentityRegistry
    function isVerified(
        address account
    ) public view returns (bool) {
        return _identities[account].verified;
    }

    /// @inheritdoc IIdentityRegistry
    function attestationHashOf(
        address account
    ) public view returns (bytes32) {
        return _identities[account].attestationHash;
    }
}
