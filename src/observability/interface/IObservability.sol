// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

interface IObservabilityEvents {
    /// > [[[[[[[[[[[ Factory events ]]]]]]]]]]]

    event CloneDeployed(
        address indexed factory,
        address indexed owner,
        address indexed clone
    );

    event FactoryImplementationSet(
        address indexed factory,
        address indexed oldImplementation,
        address indexed newImplementation
    );

    /// > [[[[[[[[[[[ Clone events ]]]]]]]]]]]

    event ContentDigestAdded(address indexed clone, bytes32 indexed digest);

    event ContentDigestRemoved(address indexed clone, bytes32 indexed digest);

    event PlatformMetadataDigestSet(
        address indexed clone,
        bytes32 indexed platformMetadataDigest
    );

    event RoleSet(
        address indexed clone,
        address indexed account,
        bytes32 indexed role,
        bool granted
    );
}

interface IObservability {
    function emitDeploymentEvent(address owner, address clone) external;

    function emitFactoryImplementationSet(
        address oldImplementation,
        address newImplementation
    ) external;

    function emitContentDigestAdded(bytes32 digest) external;

    function emitContentDigestRemoved(bytes32 digest) external;

    function emitPlatformMetadataDigestSet(bytes32 platformMetadataDigest)
        external;

    function emitRoleSet(
        address account,
        bytes32 role,
        bool granted
    ) external;
}
