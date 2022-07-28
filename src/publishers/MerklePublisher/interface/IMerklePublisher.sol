// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

interface IMerklePublisher {
    struct PublishData {
        address platform;
        bytes32[] proof;
        bytes32 contentDigest;
        uint256 nonce;
    }

    struct MerkleRootData {
        address platform;
        bytes32 merkleRoot;
        bytes32 leavesDigest;
        uint256 nonce;
    }
}
