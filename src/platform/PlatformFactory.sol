// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./Platform.sol";
import "../observability/Observability.sol";
import "../lib/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract PlatformFactory is Ownable {
    /*//////////////////////////////////////////////////////////////
                            Version
    //////////////////////////////////////////////////////////////*/

    /// @notice Version.
    uint8 public immutable VERSION = 1;

    /*//////////////////////////////////////////////////////////////
                            Deployments
    //////////////////////////////////////////////////////////////*/

    /// @notice Observability contract for data processing.
    address public immutable o11y;

    /// @notice platform implementation.
    address public implementation;

    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploys observability and implementation contracts, sets fowarder for GSN.
    constructor(address _owner) Ownable(_owner) {
        // Deploy and store Observability contract.
        o11y = address(new Observability());

        // Deploy and store implementation contract.
        implementation = address(new Platform(address(this), o11y));
    }

    /*//////////////////////////////////////////////////////////////
                            Implementation
    //////////////////////////////////////////////////////////////*/

    function setImplementation(address _implementation) external onlyOwner {
        // slither-disable-next-line reentrancy-no-eth
        IObservability(o11y).emitFactoryImplementationSet(
            // oldImplementation
            implementation,
            // newImplementation
            _implementation
        );

        // Store implementation.
        implementation = _implementation;
    }

    /*//////////////////////////////////////////////////////////////
                            Deployment functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploy a new platform clone with the sender as the owner.
    function create(
        string calldata platformMetadata,
        address[] calldata publishers,
        address[] calldata metadataManagers
    ) external returns (address clone) {
        clone = _deployCloneAndInitialize(
            msg.sender,
            IPlatform.PlatformData({
                platformMetadata: platformMetadata,
                publishers: publishers,
                metadataManagers: metadataManagers
            })
        );
    }

    /// @dev Deploys a clone and calls the initialize function
    function _deployCloneAndInitialize(
        address owner,
        Platform.PlatformData memory platform
    ) internal returns (address clone) {
        clone = Clones.clone(implementation);

        IObservability(o11y).emitDeploymentEvent(owner, clone);

        // Initialize clone.
        Platform(clone).initialize(owner, platform);
    }
}
