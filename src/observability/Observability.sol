// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "./interface/IObservability.sol";

contract Observability is IObservability, IObservabilityEvents {
    /// > [[[[[[[[[[[ Factory functions ]]]]]]]]]]]

    function emitDeploymentEvent(address owner, address clone) external override {
        emit CloneDeployed(msg.sender, owner, clone);
    }

    /// > [[[[[[[[[[[ Clone functions ]]]]]]]]]]]

    function emitContentCollectionSet(uint256 contentCollectionId, bytes32[] memory contentCollection) external override {
        emit ContentCollectionSet(msg.sender, contentCollectionId, contentCollection);
    }

    function emitContentDigestSet(uint256 contentCollectionId, uint256 contentIndex, bytes32 contentCollection) external override {
        emit ContentDigestSet(msg.sender, contentCollectionId, contentIndex, contentCollection);
    }

    function emitContentCollectionDeleted(uint256 contentCollectionId) external override {
        emit ContentCollectionDeleted(msg.sender, contentCollectionId);
    }

    function emitContentDigestDeleted(uint256 contentCollectionId, uint256 contentIndex) external override {
        emit ContentDigestDeleted(msg.sender, contentCollectionId, contentIndex);
    }

    function emitPlatformMetadataDigestSet(bytes32 platformMetadataDigest) external override {
        emit PlatformMetadataDigestSet(msg.sender, platformMetadataDigest);
    }

    function emitMetadataManagerSet(address metadataManager, bool allowed) external override {
        emit MetadataManagerSet(msg.sender, metadataManager, allowed);
    }

    function emitPublisherSet(address publisher, bool allowed) external override {
        emit PublisherSet(msg.sender, publisher, allowed);
    }
}