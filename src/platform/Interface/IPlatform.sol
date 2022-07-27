// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

interface IPlatform {
    struct PlatformData {
        bytes32 platformMetadataDigest;
        address[] publishers;
        address[] metadataManagers;
        bytes32[] initalContent;
        uint256 nonce;
    }
}
