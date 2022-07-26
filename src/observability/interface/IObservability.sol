// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

interface IObservabilityEvents {
    /// > [[[[[[[[[[[ Factory events ]]]]]]]]]]]

    event CloneDeployed(
        address indexed factory,
        address indexed owner,
        address indexed clone
    );

    /// > [[[[[[[[[[[ Clone events ]]]]]]]]]]]

    event ContentCollectionSet(
        address indexed clone,
        uint256 indexed contentCollectionId,
        bytes32[] contentCollection
    );

    event ContentDigestSet(
        address indexed clone,
        uint256 indexed contentCollectionId,
        uint256 indexed contentIndex,
        bytes32 contentCollection
    );

    event ContentCollectionDeleted(
        address indexed clone,
        uint256 contentCollectionId
    );

    event ContentDigestDeleted(
        address indexed clone,
        uint256 indexed contentCollectionId,
        uint256 indexed contentIndex
    );

    event PlatformMetadataDigestSet(
        address indexed clone,
        bytes32 indexed platformMetadataDigest
    );

    event MetadataManagerSet(
        address indexed clone,
        address indexed metadataManager,
        bool indexed allowed
    );

    event PublisherSet(
        address indexed clone,
        address indexed publisher,
        bool indexed allowed
    );
}

interface IObservability {
    function emitDeploymentEvent(address owner, address clone) external;

    function emitContentCollectionSet(uint256 contentCollectionId, bytes32[] memory contentCollection) external;

    function emitContentDigestSet(uint256 contentCollectionId, uint256 contentIndex, bytes32 contentCollection) external;

    function emitContentCollectionDeleted(uint256 contentCollectionId) external;

    function emitContentDigestDeleted(uint256 contentCollectionId, uint256 contentIndex) external;

    function emitPlatformMetadataDigestSet(bytes32 platformMetadataDigest) external;

    function emitMetadataManagerSet(address metadataManager, bool allowed) external;

    function emitPublisherSet(address publisher, bool allowed) external;
}