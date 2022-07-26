// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin/contracts/access/Ownable.sol";
import {IObservability} from "../observability/interface/IObservability.sol";

contract Platform is Ownable {

    /// @notice Version.
    uint8 public immutable VERSION = 1;

    /// @notice Address for Mirror's observability contract.
    address public immutable o11y;

    /// @notice Address that deploys and initializes clones.
    address public factory;

    /// @notice Digest of the platform metadata content
    bytes32 public platformMetadataDigest;

    /// @notice List of publishers that can add to the _contentDigests collection
    mapping(address => bool) public allowedPublishers;

    /// @notice Content owner lookup that enables owners to edit their own collections
    mapping(uint256 => address) public contentCollectionIdToOwner;

    /// @notice List of metadata managers that can set the plaform metadata digest
    mapping(address => bool) public allowedMetadataManagers;

    bytes32[][] private _contentDigests;

    modifier onlyMetadataManagerOrOwner() {
        require(allowedMetadataManagers[msg.sender] || msg.sender == owner(), "NOT_METADATA_MANAGER_OR_PLATFORM_OWNER");
        _;
    }

    modifier onlyPublisherOrOwner() {
        require(allowedPublishers[msg.sender] || msg.sender == owner(), "NOT_PUBLISHER_OR_PLATFORM_OWNER");
        _;
    }

    modifier onlyContentCollectionOwnerOrOwner(uint256 _contentCollectionId) {
        require(msg.sender == contentCollectionIdToOwner[_contentCollectionId] || msg.sender == owner(), "NOT_CONTENT_OWNER_OR_PLATFORM_OWNER");
        _;
    }

    modifier onlyExistingContentCollectionId(uint256 _contentCollectionId) {
        require(_contentDigests.length > _contentCollectionId, "CONTENT_SET_ID_DOES_NOT_EXIST");
        _;
    }

    modifier onlyExistingContentCollectionIdAndIndex(uint256 _contentCollectionId, uint256 _contentIndex) {
        require(_contentDigests.length > _contentCollectionId, "CONTENT_SET_ID_DOES_NOT_EXIST");
        require(_contentDigests[_contentCollectionId].length >= _contentIndex, "CONTENT_INDEX_DOES_NOT_EXIST");
        _;
    }

    /// > [[[[[[[[[[[ Constructor ]]]]]]]]]]]

    constructor(address _factory, address _o11y) {
        // Assert not the zero-address.
        require(_factory != address(0), "MUST_SET_FACTORY");

        // Store factory.
        factory = _factory;

         // Assert not the zero-address.
        require(_o11y != address(0), "must set observability");

        // Store observability.
        o11y = _o11y;

        transferOwnership(_factory);
    }

    /// > [[[[[[[[[[[ Initializing ]]]]]]]]]]]

    function initilize(address _owner) external {
        require(msg.sender == factory, "UNATHORIZED_CALLER");
        transferOwnership(_owner);
    }

    /// > [[[[[[[[[[[ Content Methods ]]]]]]]]]]]

    function addContentCollection(bytes32[] memory _contentCollection) external onlyPublisherOrOwner returns(uint256) {
        uint256 contentCollectionId = _contentDigests.length;
        _addContentCollection(_contentCollection);
        contentCollectionIdToOwner[contentCollectionId] = msg.sender;
        IObservability(o11y).emitContentCollectionSet(contentCollectionId, _contentCollection);
        return (contentCollectionId);
    }

    function setContentCollection(uint256 _contentCollectionId, bytes32[] memory _contentCollection) external onlyContentCollectionOwnerOrOwner(_contentCollectionId) onlyExistingContentCollectionId(_contentCollectionId) {
        _setContentCollection(_contentCollectionId, _contentCollection);
        IObservability(o11y).emitContentCollectionSet(_contentCollectionId, _contentCollection);
    }

    function setContentDigest(uint256 _contentCollectionId, uint256 _contentIndex, bytes32 _digest) external onlyContentCollectionOwnerOrOwner(_contentCollectionId) onlyExistingContentCollectionIdAndIndex(_contentCollectionId, _contentIndex) {
        _setContentDigest(_contentCollectionId, _contentIndex, _digest);
        IObservability(o11y).emitContentDigestSet(_contentCollectionId, _contentIndex, _digest);
    }

    function deleteContentCollection(uint256 _contentCollectionId) external onlyContentCollectionOwnerOrOwner(_contentCollectionId) onlyExistingContentCollectionId(_contentCollectionId) {
        _deleteContentCollection(_contentCollectionId);
        IObservability(o11y).emitContentCollectionDeleted(_contentCollectionId);
    }

    function deleteContentDigest(uint256 _contentCollectionId, uint256 _contentIndex) external onlyContentCollectionOwnerOrOwner(_contentCollectionId) onlyExistingContentCollectionIdAndIndex(_contentCollectionId, _contentIndex) {
        _deleteContentDigest(_contentCollectionId, _contentIndex);
        IObservability(o11y).emitContentDigestDeleted(_contentCollectionId, _contentIndex);
    }

    function getAllContentDigests() external view returns(bytes32[] memory) {
        uint256 size = _getPlatformContentSize();
        bytes32[] memory fullContent = new bytes32[](size);

        for(uint256 i = 0; i < _contentDigests.length; i++) {
            bytes32[] memory current = _contentDigests[i];
            for(uint256 j = 0; j < current.length; j++) {
                fullContent[i + j] = current[j];
            }
        }

        return fullContent;
    }

    function getContentCollections() external view returns(bytes32[][] memory) {
        return _contentDigests;
    }

    function getContentCollectionById(uint256 _contentCollectionId) external onlyExistingContentCollectionId(_contentCollectionId) view returns(bytes32[] memory) {
        return _contentDigests[_contentCollectionId];
    }

    /// > [[[[[[[[[[[ Platform Metadata Methods ]]]]]]]]]]]

    function setPlatformMetadataDigest(bytes32 _platformMetadataDigest) external onlyMetadataManagerOrOwner {
        platformMetadataDigest = _platformMetadataDigest;
        IObservability(o11y).emitPlatformMetadataDigestSet(_platformMetadataDigest);
    }

    /// > [[[[[[[[[[[ Role Methods ]]]]]]]]]]]

    function setMetadataManager(address _metadataManager, bool _allowed) external onlyOwner {
        _setMetadataManager(_metadataManager, _allowed);
        IObservability(o11y).emitMetadataManagerSet(_metadataManager, _allowed);
    }

    function setMetadataManagers(address[] calldata _metadataManagers, bool _allowed) external onlyOwner {
        for(uint256 i = 0; i < _metadataManagers.length; i++) {
            _setMetadataManager(_metadataManagers[i], _allowed);
            IObservability(o11y).emitMetadataManagerSet(_metadataManagers[i], _allowed);
        }
    }

    function setPublisher(address _publisher, bool _allowed) external onlyOwner {
        _setPublisher(_publisher, _allowed);
         IObservability(o11y).emitPublisherSet(_publisher, _allowed);
    }

    function setPublishers(address[] calldata _publishers, bool _allowed) external onlyOwner {
        for(uint256 i = 0; i < _publishers.length; i++) {
            allowedPublishers[_publishers[i]] = _allowed;
            IObservability(o11y).emitPublisherSet(_publishers[i], _allowed);
        }
    }
    

    /// > [[[[[[[[[[[ Internal Functions ]]]]]]]]]]]

    function _getPlatformContentSize() internal view returns (uint256) {
        uint256 size = 0;
        for(uint256 i = 0; i < _contentDigests.length; i++) {
            bytes32[] memory current = _contentDigests[i];
            size += current.length;
        }
        return size;
    }

    function _addContentCollection(bytes32[] memory _values) internal {
        _contentDigests.push(_values);
    }

    function _setContentCollection(uint256 _contentCollectionId, bytes32[] memory _values) internal {
        _contentDigests[_contentCollectionId] = _values;
    }

    function _setContentDigest(uint256 _contentCollectionId, uint256 _contentIndex, bytes32 _digest) internal {
        _contentDigests[_contentCollectionId][_contentIndex] = _digest;
    }

    function _deleteContentCollection(uint256 _contentCollectionId) internal {
        delete _contentDigests[_contentCollectionId];
    }

    function _deleteContentDigest(uint256 _contentCollectionId, uint256 _contentIndex) internal {
        delete _contentDigests[_contentCollectionId][_contentIndex];
    }

    function _setMetadataManager(address _metadataManager, bool _allowed) internal {
        allowedMetadataManagers[_metadataManager] = _allowed;
    }

    function _setPublisher(address _publisher, bool _allowed) internal {
        allowedPublishers[_publisher] = _allowed;
    }
}
