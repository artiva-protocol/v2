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

    function CONTENT_PUBLISHER_ROLE() external view returns (bytes32);

    function METADATA_MANAGER_ROLE() external view returns (bytes32);

    function VERSION() external view returns (uint8);

    function factory() external returns (address);

    function o11y() external returns (address);
}
