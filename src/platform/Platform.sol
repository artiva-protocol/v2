// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "../observability/interface/IObservability.sol";
import "./interface/IPlatform.sol";
import "../lib/Ownable.sol";

contract Platform is Ownable, IPlatform {
    /// @notice Version.
    uint8 public immutable VERSION = 1;

    /// @notice Address for observability contract.
    address public immutable o11y;

    /// @notice Address that deploys and initializes clones.
    address public factory;

    /// @notice Digest of the platform metadata content
    bytes32 public platformMetadataDigest;

    /// @notice List of publishers that can add to contentDigestToPublisher collection
    mapping(address => bool) public allowedPublishers;

    /// @notice List of metadata managers that can set the plaform metadata digest
    mapping(address => bool) public allowedMetadataManagers;

    /// @notice Mapping of content digests to their publishers
    mapping(bytes32 => address) contentDigestToPublisher;

    modifier onlyMetadataManagerOrOwner() {
        require(
            allowedMetadataManagers[msg.sender] || isOwner(),
            "NOT_METADATA_MANAGER_OR_PLATFORM_OWNER"
        );
        _;
    }

    modifier onlyPublisherOrOwner() {
        require(
            allowedPublishers[msg.sender] || isOwner(),
            "NOT_PUBLISHER_OR_PLATFORM_OWNER"
        );
        _;
    }

    modifier onlyDigestPublisherOrOwner(bytes32 _digest) {
        require(
            contentDigestToPublisher[_digest] == msg.sender || isOwner(),
            "NOT_DIGEST_PUBLISHER_OR_OWNER"
        );
        _;
    }

    /// > [[[[[[[[[[[ Constructor ]]]]]]]]]]]

    constructor(address _factory, address _o11y) Ownable(address(0)) {
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
        require(msg.sender == factory, "UNATHORIZED_CALLER");

        _setInitialOwner(factory);

        if (_platform.platformMetadataDigest.length > 0)
            platformMetadataDigest = _platform.platformMetadataDigest;

        if (_platform.initalContent.length > 0)
            addManyContentDigests(_platform.initalContent);

        if (_platform.publishers.length > 0)
            setManyPublishers(_platform.publishers, true);

        if (_platform.metadataManagers.length > 0)
            setManyMetadataManagers(_platform.metadataManagers, true);

        _setInitialOwner(_owner);
    }

    /// > [[[[[[[[[[[ Digest Methods ]]]]]]]]]]]

    function addContentDigest(bytes32 _digest) public onlyPublisherOrOwner {
        require(
            contentDigestToPublisher[_digest] == address(0),
            "DIGEST_ALREADY_PUBLISHED"
        );
        _addContentDigest(_digest, msg.sender);
        IObservability(o11y).emitContentDigestAdded(_digest);
    }

    function addManyContentDigests(bytes32[] memory _digests)
        public
        onlyPublisherOrOwner
    {
        for (uint256 i; i < _digests.length; i++) {
            addContentDigest(_digests[i]);
        }
    }

    function removeContentDigest(bytes32 _digest)
        public
        onlyDigestPublisherOrOwner(_digest)
    {
        require(
            contentDigestToPublisher[_digest] != address(0),
            "DIGEST_NOT_PUBLISHED"
        );
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
        onlyMetadataManagerOrOwner
    {
        platformMetadataDigest = _platformMetadataDigest;
        IObservability(o11y).emitPlatformMetadataDigestSet(
            _platformMetadataDigest
        );
    }

    /// > [[[[[[[[[[[ Role Methods ]]]]]]]]]]]

    function setMetadataManager(address _metadataManager, bool _allowed)
        external
        onlyOwner
    {
        _setMetadataManager(_metadataManager, _allowed);
        IObservability(o11y).emitMetadataManagerSet(_metadataManager, _allowed);
    }

    function setManyMetadataManagers(
        address[] memory _metadataManagers,
        bool _allowed
    ) public onlyOwner {
        for (uint256 i = 0; i < _metadataManagers.length; i++) {
            _setMetadataManager(_metadataManagers[i], _allowed);
            IObservability(o11y).emitMetadataManagerSet(
                _metadataManagers[i],
                _allowed
            );
        }
    }

    function setPublisher(address _publisher, bool _allowed)
        external
        onlyOwner
    {
        _setPublisher(_publisher, _allowed);
        IObservability(o11y).emitPublisherSet(_publisher, _allowed);
    }

    function setManyPublishers(address[] memory _publishers, bool _allowed)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _publishers.length; i++) {
            allowedPublishers[_publishers[i]] = _allowed;
            IObservability(o11y).emitPublisherSet(_publishers[i], _allowed);
        }
    }

    /// > [[[[[[[[[[[ Internal Functions ]]]]]]]]]]]

    function _addContentDigest(bytes32 _digest, address publisher) internal {
        contentDigestToPublisher[_digest] = publisher;
    }

    function _removeContentDigest(bytes32 _digest) internal {
        delete contentDigestToPublisher[_digest];
    }

    function _setMetadataManager(address _metadataManager, bool _allowed)
        internal
    {
        allowedMetadataManagers[_metadataManager] = _allowed;
    }

    function _setPublisher(address _publisher, bool _allowed) internal {
        allowedPublishers[_publisher] = _allowed;
    }
}
