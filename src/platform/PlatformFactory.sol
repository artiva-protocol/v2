// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./Platform.sol";
import "../observability/Observability.sol";
import "../lib/OwnableERC2771.sol";

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@opengsn/contracts/src/ERC2771Recipient.sol";

contract PlatformFactory is Ownable, ReentrancyGuard, ERC2771Recipient {
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
    constructor(address _owner, address forwarder) Ownable(_owner) {
        // Deploy and store Observability contract.
        o11y = address(new Observability());

        // Deploy and store implementation contract.
        implementation = address(new Platform(address(this), o11y));

        //Set the forwarder address for GSN
        _setTrustedForwarder(forwarder);
    }

    /*//////////////////////////////////////////////////////////////
                            View Methods
    //////////////////////////////////////////////////////////////*/

    /// @notice Generates the address that a clone will be deployed to.
    /// @param _implementation the WritingEditions address.
    /// @param salt the entropy used by create2 for generatating a deterministic address.
    function predictDeterministicAddress(address _implementation, bytes32 salt)
        external
        view
        returns (address)
    {
        return
            Clones.predictDeterministicAddress(
                _implementation,
                salt,
                address(this)
            );
    }

    function getSalt(address owner, Platform.PlatformData memory platform)
        external
        pure
        returns (bytes32)
    {
        return _getSalt(owner, platform);
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
    /// @param platform platform parameters used to deploy the clone.
    function create(Platform.PlatformData memory platform)
        external
        returns (address clone)
    {
        clone = _deployCloneAndInitialize(_msgSender(), platform);
    }

    function _getSalt(address owner, Platform.PlatformData memory platform)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    owner,
                    platform.platformMetadataURI,
                    platform.publishers,
                    platform.metadataManagers,
                    platform.initalContentURIs,
                    platform.nonce
                )
            );
    }

    /// @dev Deploys a clone and calls the initialize function
    function _deployCloneAndInitialize(
        address owner,
        Platform.PlatformData memory platform
    ) internal returns (address clone) {
        clone = Clones.cloneDeterministic(
            implementation,
            keccak256(
                abi.encode(
                    owner,
                    platform.platformMetadataURI,
                    platform.publishers,
                    platform.metadataManagers,
                    platform.initalContentURIs,
                    platform.nonce
                )
            )
        );

        IObservability(o11y).emitDeploymentEvent(owner, clone);

        // Initialize clone.
        Platform(clone).initialize(owner, getTrustedForwarder(), platform);
    }

    /*//////////////////////////////////////////////////////////////
                            Overrides
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @return ret The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender()
        internal
        view
        override(Ownable, ERC2771Recipient)
        returns (address ret)
    {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            ret = msg.sender;
        }
    }
}
