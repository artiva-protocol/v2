// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

interface IPlatform {
    struct PlatformData {
        string platformMetadataJSON;
        address[] publishers;
        address[] metadataManagers;
        uint256 nonce;
    }

    struct BundleData {
        bytes32 contentHash;
        address owner;
    }

    struct PublishAuthorization {
        string message;
        address platform;
        address publishingKey;
        uint256 nonce;
    }

    struct RoleRequest {
        address account;
        bytes32 role;
        bool grant;
    }

    function CONTENT_PUBLISHER_ROLE() external view returns (bytes32);

    function METADATA_MANAGER_ROLE() external view returns (bytes32);

    function VERSION() external view returns (uint8);

    function factory() external returns (address);

    function o11y() external returns (address);

    function getDefaultAdminRole() external view returns (bytes32);

    function addContent(string calldata bundleJSON, address owner) external;

    function setContent(uint256 bundleId, string calldata bundleJSON) external;

    function setPlatformMetadata(string calldata _platformMetadataJSON)
        external;

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function getSigningMessage(address signer) external view returns (bytes32);
}
