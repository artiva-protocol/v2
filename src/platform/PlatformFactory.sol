// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./Platform.sol";
import "../observability/Observability.sol";
import "../lib/Ownable.sol";

import "openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin/contracts/proxy/Clones.sol";
import "openzeppelin/contracts/security/ReentrancyGuard.sol";
import "openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract PlatformFactory is Ownable, ReentrancyGuard, EIP712 {
    /// @notice Version.
    uint8 public immutable VERSION = 1;

    /// @notice Observability contract for data processing.
    address public immutable o11y;

    /// > [[[[[[[[[[[ Deployments ]]]]]]]]]]]

    /// @notice platform implementation.
    address public implementation;

    /// @dev Create function separator for generating a salt.
    bytes32 public constant CREATE_TYPEHASH =
        keccak256(
            "Create(address owner,bytes32 platformMetadataDigest,address[] publishers,address[] metadataManagers,bytes32[] initalContent,uint256 nonce)"
        );

    /// > [[[[[[[[[[[ Signature Verification ]]]]]]]]]]]

    /// @notice Deploys observability and implementation contracts.
    constructor(
        address _owner,
        string memory domainName,
        string memory domainVersion
    ) Ownable(_owner) EIP712(domainName, domainVersion) {
        // Deploy and store Observability contract.
        o11y = address(new Observability());

        // Deploy and store implementation contract.
        implementation = address(new Platform(address(this), o11y));
    }

    /// > [[[[[[[[[[[ View functions ]]]]]]]]]]]

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
        view
        returns (bytes32)
    {
        return _getSalt(owner, platform);
    }

    /// > [[[[[[[[[[[ Implementation ]]]]]]]]]]]

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

    /// > [[[[[[[[[[[ Deployment functions ]]]]]]]]]]]

    /// @notice Deploy a new writing edition clone with the sender as the owner.
    /// @param platform platform parameters used to deploy the clone.
    function create(Platform.PlatformData memory platform)
        external
        returns (address clone)
    {
        clone = _deployCloneAndInitialize(msg.sender, platform);
    }

    function createWithSignature(
        address owner,
        Platform.PlatformData memory platform,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable nonReentrant returns (address clone) {
        bytes32 salt = _getSalt(owner, platform);

        // Assert the signature is valid.
        require(_isValid(owner, salt, v, r, s), "SIGNATURE_ERROR");

        clone = _deployCloneAndInitialize(owner, platform);
    }

    function _isValid(
        address owner,
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool) {
        require(owner != address(0), "CANNOT_VALIDATE");
        bytes memory signature = abi.encodePacked(r, s, v);
        return SignatureChecker.isValidSignatureNow(owner, digest, signature);
    }

    function _getSalt(address owner, Platform.PlatformData memory platform)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        CREATE_TYPEHASH,
                        owner,
                        platform.platformMetadataDigest,
                        platform.publishers,
                        platform.metadataManagers,
                        platform.initalContent,
                        platform.nonce
                    )
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
                    platform.platformMetadataDigest,
                    platform.publishers,
                    platform.metadataManagers,
                    platform.initalContent,
                    platform.nonce
                )
            )
        );

        // Initialize clone.
        Platform(clone).initialize(owner, platform);

        IObservability(o11y).emitDeploymentEvent(owner, clone);
    }
}
