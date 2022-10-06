// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/platform/Platform.sol";
import "../src/observability/Observability.sol";
import "@opengsn/contracts/src/forwarder/Forwarder.sol";

contract PlatformTest is Test {
    Platform public platform;
    address factory = address(1);

    address owner;
    uint256 internal ownerPrivateKey;

    address unauthorizedAccount;
    uint256 internal unauthorizedAccountPrivateKey;

    address fowarder;
    address publisher = address(3);
    address otherPublisher = address(4);
    address metadataManager = address(5);
    address otherMetadataManager = address(6);

    string sampleContent = "http://testcontent.com/post/1";

    function setUp() public {
        address o11y = address(new Observability());
        fowarder = address(new Forwarder());

        ownerPrivateKey = 0xA11CE;
        owner = vm.addr(ownerPrivateKey);

        unauthorizedAccountPrivateKey = 0xF11CE;
        unauthorizedAccount = vm.addr(unauthorizedAccountPrivateKey);

        platform = new Platform(factory, o11y);
    }

    /// > [[[[[[[[[[[ Initializing ]]]]]]]]]]]

    function test_initialize() public {
        initialize();
    }

    function testRevert_InitlizerNotFactory() public {
        vm.expectRevert("NOT_FACTORY");
        platform.initialize(owner, getInitalPlatformData());
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
        platform.grantRole(platform.CONTENT_PUBLISHER_ROLE(), publisher);
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
        platform.grantRole(platform.CONTENT_PUBLISHER_ROLE(), publisher);
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
        platform.grantRole(platform.CONTENT_PUBLISHER_ROLE(), publisher);
        platform.addContents(content, publisher);
        vm.stopPrank();

        vm.prank(publisher);
        platform.setContents(reqs);
    }

    function testRevert_AddContentNotAuthorized() public {
        initialize();

        string[] memory content = new string[](1);
        content[0] = sampleContent;

        vm.expectRevert("UNAUTHORIZED_ACCOUNT");
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

        vm.expectRevert("UNAUTHORIZED_ACCOUNT");
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

        vm.expectRevert("NO_OWNER");
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
        platform.grantRole(platform.CONTENT_PUBLISHER_ROLE(), publisher);
        platform.addContents(content, owner);
        vm.stopPrank();

        vm.expectRevert("SENDER_NOT_OWNER");
        vm.prank(publisher);
        platform.setContents(reqs);
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
        platform.grantRole(platform.METADATA_MANAGER_ROLE(), metadataManager);
        vm.stopPrank();

        vm.startPrank(metadataManager);
        platform.setPlatformMetadata(sampleContent);
        vm.stopPrank();
    }

    function testRevert_SetPlatformMetadataNotAuthorized() public {
        initialize();
        vm.prank(unauthorizedAccount);
        vm.expectRevert("UNAUTHORIZED_ACCOUNT");
        platform.setPlatformMetadata(sampleContent);
    }

    /// > [[[[[[[[[[[ Role Methods ]]]]]]]]]]]

    function test_SetManyRoles() public {
        initialize();

        IPlatform.RoleRequest[] memory roles = new IPlatform.RoleRequest[](4);

        roles[0] = IPlatform.RoleRequest({
            account: otherPublisher,
            role: platform.CONTENT_PUBLISHER_ROLE(),
            grant: true
        });

        roles[1] = IPlatform.RoleRequest({
            account: otherMetadataManager,
            role: platform.METADATA_MANAGER_ROLE(),
            grant: true
        });

        roles[2] = IPlatform.RoleRequest({
            account: publisher,
            role: platform.CONTENT_PUBLISHER_ROLE(),
            grant: false
        });

        roles[3] = IPlatform.RoleRequest({
            account: metadataManager,
            role: platform.METADATA_MANAGER_ROLE(),
            grant: false
        });

        vm.prank(owner);
        platform.setManyRoles(roles);

        require(
            platform.hasRole(platform.CONTENT_PUBLISHER_ROLE(), otherPublisher)
        );

        require(
            platform.hasRole(
                platform.METADATA_MANAGER_ROLE(),
                otherMetadataManager
            )
        );

        require(
            !platform.hasRole(platform.CONTENT_PUBLISHER_ROLE(), publisher)
        );

        require(
            !platform.hasRole(platform.METADATA_MANAGER_ROLE(), metadataManager)
        );
    }

    /// > [[[[[[[[[[[ Internal Functions ]]]]]]]]]]]

    function initialize() internal {
        vm.prank(factory);
        platform.initialize(owner, getInitalPlatformData());
    }

    function getInitalPlatformData()
        internal
        view
        returns (IPlatform.PlatformData memory)
    {
        address[] memory publishers = new address[](1);
        publishers[0] = owner;

        address[] memory managers = new address[](1);
        managers[0] = owner;

        return
            IPlatform.PlatformData({
                platformMetadata: sampleContent,
                publishers: publishers,
                metadataManagers: managers
            });
    }
}
