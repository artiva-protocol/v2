// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "./interface/IPlatform.sol";
import "../observability/interface/IObservability.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Platform is AccessControl, IPlatform {
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
    bytes32 public platformMetadataHash;

    /// @notice Mapping of content id to its content data.
    mapping(uint256 => ContentData) public contentIdToContentData;

    /// @dev Private content id for identifying content
    uint256 private _currentContentId = 0;

    /*//////////////////////////////////////////////////////////////
                            Platform Roles
    //////////////////////////////////////////////////////////////*/

    /// @notice Content publisher role hash for AccessControl
    bytes32 public immutable override CONTENT_PUBLISHER_ROLE =
        keccak256("CONTENT_PUBLISHER_ROLE");

    /// @notice Metadata manager role hash for AccessControl
    bytes32 public immutable override METADATA_MANAGER_ROLE =
        keccak256("METADATA_MANAGER_ROLE");

    /*//////////////////////////////////////////////////////////////
                            Modifiers
    //////////////////////////////////////////////////////////////*/

    /// @notice Checks if member is in role.
    modifier onlyRoleMember(bytes32 role, address member) {
        require(hasRole(role, member), "UNAUTHORIZED_ACCOUNT");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

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

    /*//////////////////////////////////////////////////////////////
                            View Methods
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns admin role for use in composing contracts.
    function getDefaultAdminRole() external pure override returns (bytes32) {
        return DEFAULT_ADMIN_ROLE;
    }

    /*//////////////////////////////////////////////////////////////
                            Initilization
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets default platform data must be called by factory contract.
    function initialize(address owner, PlatformData memory platform) external {
        require(msg.sender == factory, "NOT_FACTORY");

        /// > [[[[[[[[[[[ Roles ]]]]]]]]]]]

        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        IObservability(o11y).emitRoleSet(owner, DEFAULT_ADMIN_ROLE, true);

        for (uint256 i; i < platform.publishers.length; i++) {
            _setupRole(CONTENT_PUBLISHER_ROLE, platform.publishers[i]);
            IObservability(o11y).emitRoleSet(
                platform.publishers[i],
                CONTENT_PUBLISHER_ROLE,
                true
            );
        }

        for (uint256 i; i < platform.metadataManagers.length; i++) {
            _setupRole(METADATA_MANAGER_ROLE, platform.metadataManagers[i]);
            IObservability(o11y).emitRoleSet(
                platform.metadataManagers[i],
                METADATA_MANAGER_ROLE,
                true
            );
        }

        /// > [[[[[[[[[[[ Platform metadata ]]]]]]]]]]]

        platformMetadataHash = keccak256(abi.encode(platform.platformMetadata));
        IObservability(o11y).emitPlatformMetadataSet(platform.platformMetadata);
    }

    /*//////////////////////////////////////////////////////////////
                            Content Methods
    //////////////////////////////////////////////////////////////*/

    /// @notice Adds content to the platform.
    function addContents(string[] calldata contents, address owner)
        public
        override
        onlyRoleMember(CONTENT_PUBLISHER_ROLE, msg.sender)
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
        onlyRoleMember(CONTENT_PUBLISHER_ROLE, msg.sender)
    {
        for (uint256 i = 0; i < contentRequests.length; i++) {
            uint256 contentId = contentRequests[i].contentId;

            address owner = contentIdToContentData[contentId].owner;
            require(owner != address(0), "NO_OWNER");
            require(owner == msg.sender, "SENDER_NOT_OWNER");

            _setContent(contentId, contentRequests[i].content);
            IObservability(o11y).emitContentSet(
                contentId,
                contentRequests[i].content,
                owner
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                            Metadata Methods
    //////////////////////////////////////////////////////////////*/

    /// @notice Set the metadata for the platform.
    function setPlatformMetadata(string calldata _platformMetadata)
        external
        override
        onlyRoleMember(METADATA_MANAGER_ROLE, msg.sender)
    {
        platformMetadataHash = keccak256(abi.encode(_platformMetadata));
        IObservability(o11y).emitPlatformMetadataSet(_platformMetadata);
    }

    /*//////////////////////////////////////////////////////////////
                            Role Methods
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets many AccessControl roles. Useful for clients that want to batch role updates.
    function setManyRoles(RoleRequest[] calldata requests) public override {
        for (uint256 i = 0; i < requests.length; i++) {
            RoleRequest memory request = requests[i];
            if (request.grant) grantRole(request.role, request.account);
            else revokeRole(request.role, request.account);

            IObservability(o11y).emitRoleSet(
                request.account,
                request.role,
                request.grant
            );
        }
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

    /*//////////////////////////////////////////////////////////////
                            Ovverides
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Grants `role` to `account`. Overridden to support observability.
     */
    function grantRole(bytes32 role, address account)
        public
        virtual
        override(AccessControl)
        onlyRole(getRoleAdmin(role))
    {
        _grantRole(role, account);

        //Overridden to support observability
        IObservability(o11y).emitRoleSet(account, role, true);
    }

    /**
     * @dev Revokes `role` from `account`. Overridden to support observability.
     */
    function revokeRole(bytes32 role, address account)
        public
        virtual
        override(AccessControl)
        onlyRole(getRoleAdmin(role))
    {
        _revokeRole(role, account);

        //Overridden to support observability
        IObservability(o11y).emitRoleSet(account, role, false);
    }

    /**
     * @dev Revokes `role` from the calling account. Overridden to support observability.
     */
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override(AccessControl)
    {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

        _revokeRole(role, account);

        //Overridden to support observability
        IObservability(o11y).emitRoleSet(account, role, false);
    }
}
