// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "./interface/IPlatform.sol";
import "../observability/interface/IObservability.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Platform is IPlatform {
    /*//////////////////////////////////////////////////////////////
                            Version
    //////////////////////////////////////////////////////////////*/

    /// @notice Version.
    uint8 public immutable override VERSION = 1;

    /*//////////////////////////////////////////////////////////////
                            Addresses
    //////////////////////////////////////////////////////////////*/

    /// @notice Address that deploys and initializes clones.
    address public immutable override factory;

    /// @notice Address for Artiva's observability contract.
    address public immutable override o11y;

    /*//////////////////////////////////////////////////////////////
                            Platform State
    //////////////////////////////////////////////////////////////*/

    /// @notice Hash of the platform metadata
    bytes32 public metadataHash;

    /// @notice Mapping of content id to its content data.
    mapping(uint256 => ContentData) public contentIdToContentData;

    /// @dev Private content id for identifying content
    uint256 private _currentContentId = 0;

    /*//////////////////////////////////////////////////////////////
                            Platform Roles
    //////////////////////////////////////////////////////////////*/

    mapping(address => Role) public accountToRole;

    /*//////////////////////////////////////////////////////////////
                            Modifiers
    //////////////////////////////////////////////////////////////*/

    /// @notice Checks if member is in role.
    modifier onlyRoleMemberOrGreater(Role role, address member) {
        if (accountToRole[member] < role) revert Unauthorized();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address _factory, address _o11y) {
        // Assert not the zero-address.
        if (_factory == address(0)) revert MustSetFactory();

        // Store factory.
        factory = _factory;

        // Assert not the zero-address.
        if (_o11y == address(0)) revert MustSetObservability();

        // Store observability.
        o11y = _o11y;
    }

    /*//////////////////////////////////////////////////////////////
                            Initilization
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets default platform data must be called by factory contract.
    function initialize(string memory metadata, RoleRequest[] memory roles)
        external
    {
        if (msg.sender != factory) revert CallerNotFactory();

        /// > [[[[[[[[[[[ Roles ]]]]]]]]]]]
        for (uint256 i = 0; i < roles.length; i++) {
            _setRole(roles[i].account, roles[i].role);

            IObservability(o11y).emitRoleSet(
                roles[i].account,
                uint8(roles[i].role)
            );
        }

        /// > [[[[[[[[[[[ Platform metadata ]]]]]]]]]]]

        metadataHash = keccak256(abi.encode(metadata));
        IObservability(o11y).emitPlatformMetadataSet(metadata);
    }

    /*//////////////////////////////////////////////////////////////
                            View Methods
    //////////////////////////////////////////////////////////////*/

    /// @notice Check if account has a specific role.
    function hasRole(address account, Role role) public view returns (bool) {
        return accountToRole[account] == role;
    }

    /// @notice Check if account has access at or above a specific role.
    function hasAccess(address account, Role role) public view returns (bool) {
        return accountToRole[account] >= role;
    }

    /*//////////////////////////////////////////////////////////////
                            Content Methods
    //////////////////////////////////////////////////////////////*/

    /// @notice Adds content to the platform.
    function addContents(string[] calldata contents, address owner)
        public
        override
        onlyRoleMemberOrGreater(Role.PUBLISHER, msg.sender)
    {
        uint256 contentId;
        for (uint256 i = 0; i < contents.length; i++) {
            contentId = _addContent(contents[i], owner);
            IObservability(o11y).emitContentSet(contentId, contents[i], owner);
        }
    }

    /// @notice Sets content at a specific content ID. Useful for deleting or updating content.
    function setContents(SetContentRequest[] calldata contentRequests)
        public
        override
        onlyRoleMemberOrGreater(Role.PUBLISHER, msg.sender)
    {
        for (uint256 i = 0; i < contentRequests.length; i++) {
            uint256 contentId = contentRequests[i].contentId;

            address owner = contentIdToContentData[contentId].owner;
            if (owner == address(0)) revert ContentNotSet();
            if (owner != msg.sender) revert SenderNotContentOwner();

            _setContent(contentId, contentRequests[i].content);
            IObservability(o11y).emitContentSet(
                contentId,
                contentRequests[i].content,
                owner
            );
        }
    }

    /// @notice Adds content to the platform.
    function removeContent(uint256 contentId) public override {
        address owner = contentIdToContentData[contentId].owner;
        if (owner == address(0)) revert ContentNotSet();
        if (owner != msg.sender) revert SenderNotContentOwner();

        delete contentIdToContentData[contentId];
        IObservability(o11y).emitContentRemoved(contentId);
    }

    /*//////////////////////////////////////////////////////////////
                            Metadata Methods
    //////////////////////////////////////////////////////////////*/

    /// @notice Set the metadata for the platform.
    function setPlatformMetadata(string calldata _platformMetadata)
        external
        override
        onlyRoleMemberOrGreater(Role.MANAGER, msg.sender)
    {
        metadataHash = keccak256(abi.encode(_platformMetadata));
        IObservability(o11y).emitPlatformMetadataSet(_platformMetadata);
    }

    /*//////////////////////////////////////////////////////////////
                            Role Methods
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets the role for the given account.
    function setRole(address account, Role role)
        public
        override
        onlyRoleMemberOrGreater(Role.ADMIN, msg.sender)
    {
        _setRole(account, role);
        IObservability(o11y).emitRoleSet(account, uint8(role));
    }

    /// @notice Sets many roles.
    function setManyRoles(RoleRequest[] calldata requests)
        public
        override
        onlyRoleMemberOrGreater(Role.ADMIN, msg.sender)
    {
        for (uint256 i = 0; i < requests.length; i++) {
            _setRole(requests[i].account, requests[i].role);

            IObservability(o11y).emitRoleSet(
                requests[i].account,
                uint8(requests[i].role)
            );
        }
    }

    /// @notice Renounces the role for sender.
    function renounceRole() public override {
        _setRole(msg.sender, Role.UNAUTHORIZED);
        IObservability(o11y).emitRoleSet(msg.sender, uint8(Role.UNAUTHORIZED));
    }

    /*//////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Updates the current content ID then sets content for the content data mapping.
    function _addContent(string calldata content, address owner)
        internal
        returns (uint256 contentId)
    {
        contentIdToContentData[_currentContentId] = ContentData({
            contentHash: keccak256(abi.encode(content)),
            owner: owner
        });
        unchecked {
            return _currentContentId++;
        }
    }

    /// @notice Updates the content at a given content ID.
    function _setContent(uint256 contentId, string calldata content) internal {
        contentIdToContentData[contentId].contentHash = keccak256(
            abi.encode(content)
        );
    }

    /// @notice Sets the role for a given account.
    function _setRole(address account, Role role) internal {
        accountToRole[account] = role;
    }
}
