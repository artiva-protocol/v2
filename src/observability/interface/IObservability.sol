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

    event ContentSet(
        address indexed clone,
        uint256 indexed bundleId,
        string bundleJSON,
        address indexed owner
    );

    event PlatformMetadataURISet(address indexed clone, string metadataURI);

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

    function emitContentSet(
        uint256 bundleId,
        string calldata bundleJSON,
        address owner
    ) external;

    function emitPlatformMetadataURISet(string calldata metadataURI) external;

    function emitRoleSet(
        address account,
        bytes32 role,
        bool granted
    ) external;
}
