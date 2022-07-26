// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin/contracts/access/Ownable.sol";

contract Platform is Ownable {

    address public factory;
    bytes32 public platformMetadataDigest;
    mapping(address => bool) public allowedPublishers;
    mapping(uint256 => address) public contentSetIdToOwner;
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

    modifier onlyContentSetOwnerOrOwner(uint256 _contentSetId) {
        require(msg.sender == contentSetIdToOwner[_contentSetId] || msg.sender == owner(), "NOT_CONTENT_OWNER_OR_PLATFORM_OWNER");
        _;
    }

    modifier onlyExistingContentSetId(uint256 _contentSetId) {
        require(_contentDigests.length > _contentSetId, "CONTENT_SET_ID_DOES_NOT_EXIST");
        _;
    }

    modifier onlyExistingContentSetIdAndIndex(uint256 _contentSetId, uint256 _contentIndex) {
        require(_contentDigests.length > _contentSetId, "CONTENT_SET_ID_DOES_NOT_EXIST");
        require(_contentDigests[_contentSetId].length >= _contentIndex, "CONTENT_INDEX_DOES_NOT_EXIST");
        _;
    }

    /// > [[[[[[[[[[[ Constructor ]]]]]]]]]]]

    constructor(address _factory) {
        require(_factory != address(0), "MUST_SET_FACTORY");
        factory = _factory;
        transferOwnership(_factory);
    }

    /// > [[[[[[[[[[[ Initializing ]]]]]]]]]]]

    function initilize(address _owner) external {
        require(msg.sender == factory, "UNATHORIZED_CALLER");
        transferOwnership(_owner);
    }

    /// > [[[[[[[[[[[ Content Methods ]]]]]]]]]]]

    function addContentSet(bytes32[] memory _contentSet) external onlyPublisherOrOwner returns(uint256) {
        uint256 contentSetId = _contentDigests.length;
        _addContentSet(_contentSet);
        contentSetIdToOwner[contentSetId] = msg.sender;
        return (contentSetId);
    }

    function setContentSet(uint256 _contentSetId, bytes32[] memory _contentSet) external onlyContentSetOwnerOrOwner(_contentSetId) onlyExistingContentSetId(_contentSetId) {
        _setContentSet(_contentSetId, _contentSet);
    }

    function setContentDigest(uint256 _contentSetId, uint256 _contentIndex, bytes32 _digest) external onlyContentSetOwnerOrOwner(_contentSetId) onlyExistingContentSetIdAndIndex(_contentSetId, _contentIndex) {
        _setContentDigest(_contentSetId, _contentIndex, _digest);
    }

    function deleteContentSet(uint256 _contentSetId) external onlyContentSetOwnerOrOwner(_contentSetId) onlyExistingContentSetId(_contentSetId) {
        _deleteContentSet(_contentSetId);
    }

    function deleteContentDigest(uint256 _contentSetId, uint256 _contentIndex) external onlyContentSetOwnerOrOwner(_contentSetId) onlyExistingContentSetIdAndIndex(_contentSetId, _contentIndex) {
        _deleteContentDigest(_contentSetId, _contentIndex);
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

    function getContentSets() external view returns(bytes32[][] memory) {
        return _contentDigests;
    }

    function getContentSetById(uint256 _contentSetId) external onlyExistingContentSetId(_contentSetId) view returns(bytes32[] memory) {
        return _contentDigests[_contentSetId];
    }

    /// > [[[[[[[[[[[ Platform Metadata Methods ]]]]]]]]]]]

    function setPlatformMetadataDigest(bytes32 _platformMetadataDigest) external onlyMetadataManagerOrOwner {
        platformMetadataDigest = _platformMetadataDigest;
    }

    /// > [[[[[[[[[[[ Role Methods ]]]]]]]]]]]

    function setMetadataManager(address _metadataManager, bool _allowed) external onlyOwner {
        _setMetadataManager(_metadataManager, _allowed);
    }

    function setMetadataManagers(address[] calldata _metadataManagers, bool _allowed) external onlyOwner {
        for(uint256 i = 0; i < _metadataManagers.length; i++) {
            _setMetadataManager(_metadataManagers[i], _allowed);
        }
    }

    function setPublisher(address _publisher, bool _allowed) external onlyOwner {
        _setPublisher(_publisher, _allowed);
    }

    function setPublishers(address[] calldata _publishers, bool _allowed) external onlyOwner {
        for(uint256 i = 0; i < _publishers.length; i++) {
            allowedPublishers[_publishers[i]] = _allowed;
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

    function _addContentSet(bytes32[] memory _values) internal {
        _contentDigests.push(_values);
    }

    function _setContentSet(uint256 _contentSetId, bytes32[] memory _values) internal {
        _contentDigests[_contentSetId] = _values;
    }

    function _setContentDigest(uint256 _contentSetId, uint256 _contentIndex, bytes32 _digest) internal {
        _contentDigests[_contentSetId][_contentIndex] = _digest;
    }

    function _deleteContentSet(uint256 _contentSetId) internal {
        delete _contentDigests[_contentSetId];
    }

    function _deleteContentDigest(uint256 _contentSetId, uint256 _contentIndex) internal {
        delete _contentDigests[_contentSetId][_contentIndex];
    }

    function _setMetadataManager(address _metadataManager, bool _allowed) internal {
        allowedMetadataManagers[_metadataManager] = _allowed;
    }

    function _setPublisher(address _publisher, bool _allowed) internal {
        allowedPublishers[_publisher] = _allowed;
    }
}
