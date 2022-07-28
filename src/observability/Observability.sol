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

    function emitContentDigestAdded(bytes32 digest, address owner)
        external
        override
    {
        emit ContentDigestAdded(msg.sender, digest, owner);
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

    function emitRoleSet(
        address account,
        bytes32 role,
        bool granted
    ) external override {
        emit RoleSet(msg.sender, account, role, granted);
    }
}
