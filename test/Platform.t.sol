// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/platform/Platform.sol";
import "../src/observability/Observability.sol";
import "@opengsn/contracts/src/forwarder/Forwarder.sol";

contract PlatformTest is Test {
    Platform public platform;

    address factory = address(1);
    address owner = address(2);
    address publisher = address(3);
    address otherPublisher = address(4);
    address metadataManager = address(5);
    address otherMetadataManager = address(6);
    address unauthorizedAccount = address(7);

    string sampleContent = "http://testcontent.com/post/1";

    function setUp() public {
        address o11y = address(new Observability());
        platform = new Platform(factory, o11y);
    }

    /// > [[[[[[[[[[[ Initializing ]]]]]]]]]]]

    function test_initialize() public {
        initialize();
    }

    function testRevert_InitlizerNotFactory() public {
        vm.expectRevert(IPlatform.CallerNotFactory.selector);
        (
            string memory metadata,
            IPlatform.RoleRequest[] memory roles
        ) = getInitalPlatformData();
        platform.initialize(metadata, roles);
    }

    /// > [[[[[[[[[[[ Content Methods ]]]]]]]]]]]

    function test_AddContentOwner() public {
        initialize();

        vm.prank(owner);
        string[] memory content = new string[](1);
        content[0] = sampleContent;

        platform.addContents(content, owner);
    }

    function test_AddContentPublisher() public {
        initialize();

        vm.startPrank(owner);
        platform.setRole(publisher, IPlatform.Role.PUBLISHER);
        vm.stopPrank();

        string[] memory content = new string[](1);
        content[0] = sampleContent;

        vm.startPrank(publisher);
        platform.addContents(content, publisher);
        vm.stopPrank();
    }

    function test_SetContentOwner() public {
        initialize();

        string[] memory content = new string[](1);
        content[0] = sampleContent;

        IPlatform.SetContentRequest[]
            memory reqs = new IPlatform.SetContentRequest[](1);
        reqs[0] = IPlatform.SetContentRequest({
            contentId: 0,
            content: sampleContent
        });

        vm.startPrank(owner);
        platform.addContents(content, owner);
        platform.setContents(reqs);
        vm.stopPrank();
    }

    function test_SetContentPublisher() public {
        initialize();

        string[] memory content = new string[](1);
        content[0] = sampleContent;

        IPlatform.SetContentRequest[]
            memory reqs = new IPlatform.SetContentRequest[](1);
        reqs[0] = IPlatform.SetContentRequest({
            contentId: 0,
            content: sampleContent
        });

        vm.startPrank(owner);
        platform.setRole(publisher, IPlatform.Role.PUBLISHER);
        vm.stopPrank();

        vm.startPrank(publisher);
        platform.addContents(content, publisher);
        platform.setContents(reqs);
        vm.stopPrank();
    }

    function testRevert_SetContentOwnerSettingForAnother() public {
        initialize();

        string[] memory content = new string[](1);
        content[0] = sampleContent;

        IPlatform.SetContentRequest[]
            memory reqs = new IPlatform.SetContentRequest[](1);
        reqs[0] = IPlatform.SetContentRequest({
            contentId: 0,
            content: sampleContent
        });

        vm.startPrank(owner);
        platform.setRole(publisher, IPlatform.Role.PUBLISHER);
        platform.addContents(content, publisher);
        vm.stopPrank();

        vm.prank(publisher);
        platform.setContents(reqs);
    }

    function testRevert_AddContentNotAuthorized() public {
        initialize();

        string[] memory content = new string[](1);
        content[0] = sampleContent;

        vm.expectRevert(IPlatform.Unauthorized.selector);
        platform.addContents(content, owner);
    }

    function testRevert_SetContentNotAuthorized() public {
        initialize();

        IPlatform.SetContentRequest[]
            memory reqs = new IPlatform.SetContentRequest[](1);
        reqs[0] = IPlatform.SetContentRequest({
            contentId: 0,
            content: sampleContent
        });

        vm.expectRevert(IPlatform.Unauthorized.selector);
        platform.setContents(reqs);
    }

    function testRevert_SetContentNoOwner() public {
        initialize();

        IPlatform.SetContentRequest[]
            memory reqs = new IPlatform.SetContentRequest[](1);
        reqs[0] = IPlatform.SetContentRequest({
            contentId: 0,
            content: sampleContent
        });

        vm.expectRevert(IPlatform.ContentNotSet.selector);
        vm.prank(owner);
        platform.setContents(reqs);
    }

    function testRevert_SetContentSenderNotOwner() public {
        initialize();

        string[] memory content = new string[](1);
        content[0] = sampleContent;

        IPlatform.SetContentRequest[]
            memory reqs = new IPlatform.SetContentRequest[](1);
        reqs[0] = IPlatform.SetContentRequest({
            contentId: 0,
            content: sampleContent
        });

        vm.startPrank(owner);
        platform.setRole(publisher, IPlatform.Role.PUBLISHER);
        platform.addContents(content, owner);
        vm.stopPrank();

        vm.expectRevert(IPlatform.SenderNotContentOwner.selector);
        vm.prank(publisher);
        platform.setContents(reqs);
    }

    function test_RemoveContentOwner() public {
        initialize();

        string[] memory content = new string[](1);
        content[0] = sampleContent;

        vm.startPrank(owner);
        platform.addContents(content, owner);
        platform.removeContent(0);
        vm.stopPrank();
    }

    function test_RemoveContentPublisher() public {
        initialize();

        string[] memory content = new string[](1);
        content[0] = sampleContent;

        vm.prank(owner);
        platform.setRole(publisher, IPlatform.Role.PUBLISHER);

        vm.startPrank(publisher);
        platform.addContents(content, publisher);
        platform.removeContent(0);
        vm.stopPrank();
    }

    function test_RemoveContentNoRole() public {
        initialize();

        string[] memory content = new string[](1);
        content[0] = sampleContent;

        vm.prank(owner);
        platform.addContents(content, unauthorizedAccount);

        vm.prank(unauthorizedAccount);
        platform.removeContent(0);
    }

    function testRevert_RemoveContentSenderNotOwner() public {
        initialize();

        string[] memory content = new string[](1);
        content[0] = sampleContent;

        vm.prank(owner);
        platform.addContents(content, owner);

        vm.prank(unauthorizedAccount);
        vm.expectRevert(IPlatform.SenderNotContentOwner.selector);
        platform.removeContent(0);
    }

    /// > [[[[[[[[[[[ Platform Metadata Methods ]]]]]]]]]]]

    function test_SetPlatformMetadataDigestOwner() public {
        initialize();

        vm.prank(owner);
        platform.setPlatformMetadata(sampleContent);
    }

    function test_SetPlatformMetadataDigestMetadataManager() public {
        initialize();

        vm.startPrank(owner);
        platform.setRole(metadataManager, IPlatform.Role.MANAGER);
        vm.stopPrank();

        vm.startPrank(metadataManager);
        platform.setPlatformMetadata(sampleContent);
        vm.stopPrank();
    }

    function testRevert_SetPlatformMetadataNotAuthorized() public {
        initialize();
        vm.prank(unauthorizedAccount);
        vm.expectRevert(IPlatform.Unauthorized.selector);
        platform.setPlatformMetadata(sampleContent);
    }

    /// > [[[[[[[[[[[ Role Methods ]]]]]]]]]]]

    function test_SetRole() public {
        initialize();

        vm.prank(owner);
        platform.setRole(otherPublisher, IPlatform.Role.PUBLISHER);

        require(platform.hasRole(otherPublisher, IPlatform.Role.PUBLISHER));
    }

    function testRevert_SetRoleUnathorized() public {
        initialize();

        vm.prank(unauthorizedAccount);
        vm.expectRevert(IPlatform.Unauthorized.selector);
        platform.setRole(otherPublisher, IPlatform.Role.PUBLISHER);
    }

    function test_RenounceRole() public {
        initialize();

        vm.prank(owner);
        platform.setRole(otherPublisher, IPlatform.Role.PUBLISHER);

        vm.prank(otherPublisher);
        platform.renounceRole();

        require(platform.hasRole(otherPublisher, IPlatform.Role.UNAUTHORIZED));
    }

    function test_SetManyRoles() public {
        initialize();

        IPlatform.RoleRequest[] memory roles = new IPlatform.RoleRequest[](4);

        roles[0] = IPlatform.RoleRequest({
            account: otherPublisher,
            role: IPlatform.Role.PUBLISHER
        });

        roles[1] = IPlatform.RoleRequest({
            account: otherMetadataManager,
            role: IPlatform.Role.MANAGER
        });

        roles[2] = IPlatform.RoleRequest({
            account: publisher,
            role: IPlatform.Role.UNAUTHORIZED
        });

        roles[3] = IPlatform.RoleRequest({
            account: metadataManager,
            role: IPlatform.Role.UNAUTHORIZED
        });

        vm.prank(owner);
        platform.setManyRoles(roles);

        require(platform.hasRole(otherPublisher, IPlatform.Role.PUBLISHER));
        require(platform.hasRole(otherMetadataManager, IPlatform.Role.MANAGER));

        require(platform.hasRole(publisher, IPlatform.Role.UNAUTHORIZED));
        require(platform.hasRole(metadataManager, IPlatform.Role.UNAUTHORIZED));
    }

    function testRevert_SetManyRolesUnauthorized() public {
        initialize();

        IPlatform.RoleRequest[] memory roles = new IPlatform.RoleRequest[](4);

        roles[0] = IPlatform.RoleRequest({
            account: otherPublisher,
            role: IPlatform.Role.PUBLISHER
        });

        roles[1] = IPlatform.RoleRequest({
            account: otherMetadataManager,
            role: IPlatform.Role.MANAGER
        });

        roles[2] = IPlatform.RoleRequest({
            account: publisher,
            role: IPlatform.Role.UNAUTHORIZED
        });

        roles[3] = IPlatform.RoleRequest({
            account: metadataManager,
            role: IPlatform.Role.UNAUTHORIZED
        });

        vm.prank(unauthorizedAccount);
        vm.expectRevert(IPlatform.Unauthorized.selector);
        platform.setManyRoles(roles);
    }

    /// > [[[[[[[[[[[ Internal Functions ]]]]]]]]]]]

    function initialize() internal {
        vm.prank(factory);
        (
            string memory metadata,
            IPlatform.RoleRequest[] memory roles
        ) = getInitalPlatformData();
        platform.initialize(metadata, roles);
    }

    function getInitalPlatformData()
        internal
        view
        returns (string memory metadata, IPlatform.RoleRequest[] memory roles)
    {
        roles = new IPlatform.RoleRequest[](2);
        roles[0] = IPlatform.RoleRequest({
            role: IPlatform.Role.ADMIN,
            account: owner
        });

        return (sampleContent, roles);
    }
}
