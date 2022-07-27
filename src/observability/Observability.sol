// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "./interface/IObservability.sol";

contract Observability is IObservability, IObservabilityEvents {
    /// > [[[[[[[[[[[ Factory functions ]]]]]]]]]]]

    function emitDeploymentEvent(address owner, address clone)
        external
        override
    {
        emit CloneDeployed(msg.sender, owner, clone);
    }

    function emitFactoryImplementationSet(
        address oldImplementation,
        address newImplementation
    ) external override {
        emit FactoryImplementationSet(
            msg.sender,
            oldImplementation,
            newImplementation
        );
    }

    /// > [[[[[[[[[[[ Clone functions ]]]]]]]]]]]

    function emitContentDigestAdded(bytes32 digest) external override {
        emit ContentDigestAdded(msg.sender, digest);
    }

    function emitContentDigestRemoved(bytes32 digest) external override {
        emit ContentDigestRemoved(msg.sender, digest);
    }

    function emitPlatformMetadataDigestSet(bytes32 platformMetadataDigest)
        external
        override
    {
        emit PlatformMetadataDigestSet(msg.sender, platformMetadataDigest);
    }

    function emitMetadataManagerSet(address metadataManager, bool allowed)
        external
        override
    {
        emit MetadataManagerSet(msg.sender, metadataManager, allowed);
    }

    function emitPublisherSet(address publisher, bool allowed)
        external
        override
    {
        emit PublisherSet(msg.sender, publisher, allowed);
    }
}
