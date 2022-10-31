// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

interface IPlatform {
    /*//////////////////////////////////////////////////////////////
                            Structs
    //////////////////////////////////////////////////////////////*/

    struct ContentData {
        bytes32 contentHash;
        address owner;
    }

    struct SetContentRequest {
        uint256 contentId;
        string content;
    }

    struct RoleRequest {
        address account;
        Role role;
    }

    /*//////////////////////////////////////////////////////////////
                            Enums
    //////////////////////////////////////////////////////////////*/

    enum Role {
        UNAUTHORIZED,
        PUBLISHER,
        MANAGER,
        ADMIN
    }

    /*//////////////////////////////////////////////////////////////
                            Errors
    //////////////////////////////////////////////////////////////*/

    error Unauthorized();

    error MustSetFactory();
    error MustSetObservability();

    error CallerNotFactory();

    error ContentNotSet();
    error SenderNotContentOwner();

    /*//////////////////////////////////////////////////////////////
                            Methods
    //////////////////////////////////////////////////////////////*/

    function VERSION() external view returns (uint8);

    function factory() external returns (address);

    function o11y() external returns (address);

    function accountToRole(address account) external returns (Role);

    function hasRole(address account, Role role) external view returns (bool);

    function hasAccess(address account, Role role) external view returns (bool);

    function addContents(string[] calldata contents, address owner) external;

    function setContents(SetContentRequest[] calldata setContentRequests)
        external;

    function removeContent(uint256 contentId) external;

    function setPlatformMetadata(string calldata _platformMetadataJSON)
        external;

    function renounceRole() external;

    function setRole(address account, Role role) external;

    function setManyRoles(RoleRequest[] calldata requests) external;
}
