// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/// @dev Interafce for EIP-1271: Standard Signature Validation Method for Contracts.
interface IERC1271 {
    /// @dev Should return whether the signature provided is valid for the provided hash
    /// @param salt      Hash of the data to be signed
    /// @param signature Signature byte array associated with _hash
    /// MUST return the bytes4 magic value 0x1626ba7e when function passes.
    /// MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
    /// MUST allow external calls
    function isValidSignature(bytes32 salt, bytes memory signature)
        external
        view
        returns (bytes4 magicValue);
}
