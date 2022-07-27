// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "../observability/interface/IObservability.sol";
import "./interface/IPlatform.sol";

import "openzeppelin/contracts/access/AccessControl.sol";

contract Platform is AccessControl, IPlatform {
    /// > [[[[[[[[[[[ Version ]]]]]]]]]]]

    /// @notice Version.
    uint8 public immutable override VERSION = 1;

    /// > [[[[[[[[[[[ Authorization ]]]]]]]]]]]

    /// @notice Address that deploys and initializes clones.
    address public immutable override factory;

    /// > [[[[[[[[[[[ Configuration ]]]]]]]]]]]

    /// @notice Address for Mirror's observability contract.
    address public immutable override o11y;

    /// @notice Digest of the platform metadata content
    bytes32 public platformMetadataDigest;

    /// @notice Mapping of content digests to their publishers
    mapping(bytes32 => address) contentDigestToPublisher;

    bytes32 public constant override CONTENT_PUBLISHER_ROLE =
        keccak256("CONTENT_PUBLISHER_ROLE");

    bytes32 public constant override METADATA_MANAGER_ROLE =
        keccak256("METADATA_MANAGER_ROLE");

    modifier onlyDigestPublisher(bytes32 _digest) {
        require(
            contentDigestToPublisher[_digest] == msg.sender,
            "NOT_DIGEST_PUBLISHER"
        );
        _;
    }

    modifier onlyRoleMember(bytes32 role) {
        require(hasRole(role, msg.sender), "UNAUTHORIZED_CALLER");
        _;
    }

    /// > [[[[[[[[[[[ Constructor ]]]]]]]]]]]

    constructor(address _factory, address _o11y) {
        // Assert not the zero-address.
        require(_factory != address(0), "MUST_SET_FACTORY");

        // Store factory.
        factory = _factory;

        // Assert not the zero-address.
        require(_o11y != address(0), "MUST_SET_OBSERVABILITY");

        // Store observability.
        o11y = _o11y;
    }

    /// > [[[[[[[[[[[ Initializing ]]]]]]]]]]]

    function initialize(address _owner, PlatformData memory _platform)
        external
    {
        require(msg.sender == factory, "NOT_FACTORY");

        if (_platform.platformMetadataDigest.length > 0)
            platformMetadataDigest = _platform.platformMetadataDigest;

        for (uint256 i; i < _platform.initalContent.length; i++) {
            _addContentDigest(_platform.initalContent[i], _owner);
            IObservability(o11y).emitContentDigestAdded(
                _platform.initalContent[i]
            );
        }

        for (uint256 i; i < _platform.publishers.length; i++) {
            _setupRole(CONTENT_PUBLISHER_ROLE, _platform.publishers[i]);
            IObservability(o11y).emitRoleSet(
                _platform.publishers[i],
                CONTENT_PUBLISHER_ROLE,
                true
            );
        }

        for (uint256 i; i < _platform.metadataManagers.length; i++) {
            _setupRole(METADATA_MANAGER_ROLE, _platform.metadataManagers[i]);
            IObservability(o11y).emitRoleSet(
                _platform.metadataManagers[i],
                METADATA_MANAGER_ROLE,
                true
            );
        }

        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
    }

    /// > [[[[[[[[[[[ Digest Methods ]]]]]]]]]]]

    function addContentDigest(bytes32 _digest)
        public
        onlyRoleMember(CONTENT_PUBLISHER_ROLE)
    {
        require(
            contentDigestToPublisher[_digest] == address(0),
            "DIGEST_ALREADY_PUBLISHED"
        );
        _addContentDigest(_digest, msg.sender);
        IObservability(o11y).emitContentDigestAdded(_digest);
    }

    function addManyContentDigests(bytes32[] memory _digests) public {
        for (uint256 i; i < _digests.length; i++) {
            addContentDigest(_digests[i]);
        }
    }

    function removeContentDigest(bytes32 _digest)
        public
        onlyDigestPublisher(_digest)
    {
        _removeContentDigest(_digest);
        IObservability(o11y).emitContentDigestRemoved(_digest);
    }

    function removeManyContentDigests(bytes32[] memory _digests) public {
        for (uint256 i; i < _digests.length; i++) {
            removeContentDigest(_digests[i]);
        }
    }

    /// > [[[[[[[[[[[ Platform Metadata Methods ]]]]]]]]]]]

    function setPlatformMetadataDigest(bytes32 _platformMetadataDigest)
        external
        onlyRoleMember(METADATA_MANAGER_ROLE)
    {
        platformMetadataDigest = _platformMetadataDigest;
        IObservability(o11y).emitPlatformMetadataDigestSet(
            _platformMetadataDigest
        );
    }

    /// > [[[[[[[[[[[ Role Methods ]]]]]]]]]]]

    function setManyRoles(
        address[] memory _accounts,
        bytes32 _role,
        bool _grant
    ) public {
        for (uint256 i = 0; i < _accounts.length; i++) {
            if (_grant) grantRole(_role, _accounts[i]);
            else revokeRole(_role, _accounts[i]);

            IObservability(o11y).emitRoleSet(_accounts[i], _role, _grant);
        }
    }

    /// > [[[[[[[[[[[ Internal Functions ]]]]]]]]]]]

    function _addContentDigest(bytes32 _digest, address publisher) internal {
        contentDigestToPublisher[_digest] = publisher;
    }

    function _removeContentDigest(bytes32 _digest) internal {
        delete contentDigestToPublisher[_digest];
    }
}
