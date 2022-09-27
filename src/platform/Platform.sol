// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "../observability/interface/IObservability.sol";
import "./interface/IPlatform.sol";
import "../lib/AccessControlERC2771.sol";
import "@opengsn/contracts/src/ERC2771Recipient.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Platform is AccessControl, IPlatform, ERC2771Recipient {
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
                            Signature Configuation
    //////////////////////////////////////////////////////////////*/

    /// @notice Domain seperator for typed data
    bytes32 public DOMAIN_SEPARATOR;

    /// @notice Mapping of address to its signature nonce used for publishing with signature.
    mapping(address => uint256) addressToSignatureNonce;

    /// @notice Typed data struct for publishing authorization
    bytes32 public immutable PUBLISH_AUTHORIZATION_TYPEHASH =
        keccak256(
            "PublishAuthorization(string message,address publishingKey,uint256 nonce)"
        );

    /*//////////////////////////////////////////////////////////////
                            Platform State
    //////////////////////////////////////////////////////////////*/

    /// @notice URI of the platform metadata content
    string public platformMetadataURI;

    /// @notice Mapping of content id to its content data.
    mapping(uint256 => ContentData) contentIdToContentData;

    /// @notice Private content id for indexing content
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

    /// @notice Checks if publishing signature is valid.
    modifier onlyValidSignature(address signer, bytes calldata signature) {
        require(
            SignatureChecker.isValidSignatureNow(
                signer,
                getSigningMessage(signer),
                signature
            ),
            "UNATHORIZED_SIGNATURE"
        );
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
    function getDefaultAdminRole() external pure returns (bytes32) {
        return DEFAULT_ADMIN_ROLE;
    }

    /// @notice Get typed data message for clients to execute functions with publishing keys.
    function getSigningMessage(address signer) public view returns (bytes32) {
        return
            ECDSA.toTypedDataHash(
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PUBLISH_AUTHORIZATION_TYPEHASH,
                        keccak256(
                            bytes(
                                "I authorize publishing on artiva from this device"
                            )
                        ),
                        _msgSender(),
                        addressToSignatureNonce[signer]
                    )
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                            Initilization
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets default platform data must be called by factory contract.
    function initialize(
        address owner,
        address forwarder,
        PlatformData memory platform
    ) external {
        require(_msgSender() == factory, "NOT_FACTORY");

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

        platformMetadataURI = platform.platformMetadataURI;

        /// > [[[[[[[[[[[ GSN ]]]]]]]]]]]

        require(forwarder != address(0), "MUST_SET_FORWARDER");
        _setTrustedForwarder(forwarder);

        /// > [[[[[[[[[[[ Typed data ]]]]]]]]]]]

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
    }

    /*//////////////////////////////////////////////////////////////
                            Content Methods
    //////////////////////////////////////////////////////////////*/

    /// @notice Adds content to the platform.
    function addContent(string calldata contentURI, address owner)
        public
        onlyRoleMember(CONTENT_PUBLISHER_ROLE, _msgSender())
    {
        uint256 contentId = _addContent(contentURI, owner);
        IObservability(o11y).emitContentSet(contentId, contentURI, owner);
    }

    /// @notice Sets content at a specific content ID. Useful for deleting of updating content.
    function setContent(uint256 contentId, string calldata contentURI)
        public
        onlyRoleMember(CONTENT_PUBLISHER_ROLE, _msgSender())
    {
        address owner = contentIdToContentData[contentId].owner;
        require(owner != address(0), "NO_OWNER");
        require(owner == _msgSender(), "SENDER_NOT_OWNER");

        _setContent(contentId, contentURI);
        IObservability(o11y).emitContentSet(contentId, contentURI, owner);
    }

    /*//////////////////////////////////////////////////////////////
                            Metadata Methods
    //////////////////////////////////////////////////////////////*/

    /// @notice Set the metadata uri for the platform.
    function setPlatformMetadataURI(string calldata _platformMetadataURI)
        external
        onlyRoleMember(METADATA_MANAGER_ROLE, _msgSender())
    {
        platformMetadataURI = _platformMetadataURI;
        IObservability(o11y).emitPlatformMetadataURISet(_platformMetadataURI);
    }

    /*//////////////////////////////////////////////////////////////
                            Role Methods
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets many AccessControl roles. Useful for clients that want to batch role updates.
    function setManyRoles(RoleRequest[] calldata requests) public {
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
                            Signature Methods
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets the signature nonce, can be used if a user wants to invalidate their publishing signature.
    function setSignatureNonce(uint256 nonce) external {
        addressToSignatureNonce[_msgSender()] = nonce;
    }

    /// @notice Adds content to the platform with support for publishing signatures.
    function addContentWithSig(
        string calldata contentURI,
        address owner,
        address signer,
        bytes calldata signature
    )
        external
        onlyRoleMember(CONTENT_PUBLISHER_ROLE, signer)
        onlyValidSignature(signer, signature)
    {
        uint256 contentId = _addContent(contentURI, owner);
        IObservability(o11y).emitContentSet(contentId, contentURI, owner);
    }

    /// @notice Sets content with support for publishing signatures.
    function setContentWithSig(
        uint256 contentId,
        string calldata contentURI,
        address signer,
        bytes calldata signature
    )
        external
        onlyRoleMember(CONTENT_PUBLISHER_ROLE, signer)
        onlyValidSignature(signer, signature)
    {
        address owner = contentIdToContentData[contentId].owner;
        require(owner != address(0), "NO_OWNER");
        require(owner == signer, "SENDER_NOT_OWNER");

        _setContent(contentId, contentURI);
        IObservability(o11y).emitContentSet(contentId, contentURI, owner);
    }

    /// @notice Set the metadata uri for the platform with support for publishing signatures.
    function setPlatformMetadataURIWithSig(
        string calldata _platformMetadataURI,
        address signer,
        bytes calldata signature
    )
        external
        onlyRoleMember(METADATA_MANAGER_ROLE, signer)
        onlyValidSignature(signer, signature)
    {
        platformMetadataURI = _platformMetadataURI;
        IObservability(o11y).emitPlatformMetadataURISet(_platformMetadataURI);
    }

    /// @notice Sets many AccessControl with support for publishing signatures.
    function setManyRolesWithSig(
        RoleRequest[] calldata requests,
        address signer,
        bytes calldata signature
    ) public onlyValidSignature(signer, signature) {
        for (uint256 i = 0; i < requests.length; i++) {
            RoleRequest memory request = requests[i];

            require(
                hasRole(getRoleAdmin(request.role), signer),
                "UNAUTHORIZED_ACCOUNT"
            );

            if (request.grant) _grantRole(request.role, request.account);
            else _revokeRole(request.role, request.account);

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
    function _addContent(string calldata contentURI, address owner)
        internal
        returns (uint256 contentId)
    {
        contentIdToContentData[_currentContentId] = ContentData({
            contentURI: contentURI,
            owner: owner
        });
        unchecked {
            return _currentContentId++;
        }
    }

    /// @notice Updates the content at a given content ID.
    function _setContent(uint256 contentId, string calldata contentURI)
        internal
    {
        contentIdToContentData[contentId].contentURI = contentURI;
    }

    /*//////////////////////////////////////////////////////////////
                            Ovverides
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Grants `role` to `account`. Overridden to support observability.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account)
        public
        virtual
        override(AccessControl, IPlatform)
        onlyRole(getRoleAdmin(role))
    {
        _grantRole(role, account);

        //Overridden to support observability
        IObservability(o11y).emitRoleSet(account, role, true);
    }

    /**
     * @dev Revokes `role` from `account`. Overridden to support observability.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account)
        public
        virtual
        override(AccessControl, IPlatform)
        onlyRole(getRoleAdmin(role))
    {
        _revokeRole(role, account);

        //Overridden to support observability
        IObservability(o11y).emitRoleSet(account, role, false);
    }

    /**
     * @dev Revokes `role` from the calling account. Overridden to support observability.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
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

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @dev Overridden due to conflict with AccessControl _msgSender.
     * @return ret The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender()
        internal
        view
        override(AccessControl, ERC2771Recipient)
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
