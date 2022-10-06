// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

interface IPlatform {
    struct PlatformData {
        string platformMetadata;
        address[] publishers;
        address[] metadataManagers;
    }

    struct ContentData {
        bytes32 contentHash;
        address owner;
    }

    struct SetContentRequest {
        uint256 contentId;
        string content;
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

    function addContents(string[] calldata contents, address owner) external;

    function setContents(SetContentRequest[] calldata setContentRequests)
        external;

    function setPlatformMetadata(string calldata _platformMetadataJSON)
        external;

    function setManyRoles(RoleRequest[] calldata requests) external;
}
