// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./Platform.sol";
import "../observability/Observability.sol";
import "../lib/ERC1271/interface/IERC1271.sol";
import "../lib/Ownable.sol";

import "openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin/contracts/proxy/Clones.sol";
import "openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PlatformFactory is Ownable, ReentrancyGuard {
    /// @notice Version.
    uint8 public immutable VERSION = 1;

    /// @notice Observability contract for data processing.
    address public immutable o11y;

    /// > [[[[[[[[[[[ Deployments ]]]]]]]]]]]

    /// @notice platform implementation.
    address public implementation;

    /// @dev Contract/domain separator for generating a salt.
    bytes32 public immutable DOMAIN_SEPARATOR;

    /// @dev Create function separator for generating a salt.
    bytes32 public constant CREATE_TYPEHASH =
        keccak256(
            "Create(address owner,bytes32 platformMetadataDigest,address[] publishers,address[] metadataManagers,bytes32[] initalContent,uint256 nonce)"
        );

    /// > [[[[[[[[[[[ Signature Verification ]]]]]]]]]]]

    /// @dev Used to verify smart contract signatures (ERC1271).
    bytes4 internal constant MAGIC_VALUE =
        bytes4(keccak256("isValidSignature(bytes32,bytes)"));

    /// @notice Deploys observability and implementation contracts.
    constructor(address _owner) Ownable(_owner) {
        // Deploy and store Observability contract.
        o11y = address(new Observability());

        // Generate domain separator.
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

        // Deploy and store implementation contract.
        implementation = address(new Platform(address(this), o11y));
    }

    /// > [[[[[[[[[[[ View functions ]]]]]]]]]]]

    function getMessageHash(
        address owner,
        Platform.PlatformData memory platform
    ) external view returns (bytes32) {
        return _getMessageHash(owner, platform);
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
        bytes32 messageHash = _getMessageHash(owner, platform);

        // Assert the signature is valid.
        require(_isValid(owner, messageHash, v, r, s), "SIGNATURE_ERROR");

        clone = _deployCloneAndInitialize(owner, platform);
    }

    function _isValid(
        address owner,
        bytes32 messageHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool) {
        require(owner != address(0), "CANNOT_VALIDATE");

        // If the owner is a contract, attempt to validate the
        // signature using EIP-1271.
        if (owner.code.length != 0) {
            bytes memory signature = abi.encodePacked(r, s, v);

            // slither-disable-next-line unused-return
            try
                IERC1271(owner).isValidSignature(messageHash, signature)
            returns (
                // slither-disable-next-line uninitialized-local
                bytes4 magicValue
            ) {
                return MAGIC_VALUE == magicValue;
            } catch {
                return false;
            }
        }

        address recoveredAddress = ECDSA.recover(messageHash, v, r, s);

        return recoveredAddress == owner;
    }

    function _getMessageHash(
        address owner,
        Platform.PlatformData memory platform
    ) internal view returns (bytes32) {
        return
            ECDSA.toTypedDataHash(
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        CREATE_TYPEHASH,
                        owner,
                        platform.platformMetadataDigest,
                        platform.publishers,
                        platform.metadataManagers,
                        platform.initalContent
                    )
                )
            );
    }

    /// @dev Deploys a clone and calls the initialize function
    function _deployCloneAndInitialize(
        address owner,
        Platform.PlatformData memory platform
    ) internal returns (address clone) {
        clone = Clones.clone(implementation);

        // Initialize clone.
        Platform(clone).initialize(owner, platform);

        IObservability(o11y).emitDeploymentEvent(owner, clone);
    }
}
