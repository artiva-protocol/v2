// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/platform/Platform.sol";
import "../src/observability/Observability.sol";

contract PlatformTest is Test {
    Platform public platform;
    address factory = 0x0000000000000000000000000000000000000001;
    address owner = 0x0000000000000000000000000000000000000002;
    address publisher = 0x0000000000000000000000000000000000000003;
    address otherPublisher = 0x0000000000000000000000000000000000000004;
    address metadataManager = 0x0000000000000000000000000000000000000005;
    address otherMetadataManager = 0x0000000000000000000000000000000000000006;
    bytes32 sampleDigest = "W7_vCzkbZ_IJE9fsdoE4-trgeYpiWsds";
    bytes32 otherSampleDigest = "B8_vCzkbZ_IJE9fsdoE4-trgeYpiWsds";

    IPlatform.PlatformData initialPlatformData =
        IPlatform.PlatformData({
            platformMetadataDigest: "",
            publishers: new address[](0),
            metadataManagers: new address[](0),
            initalContent: new bytes32[](0),
            nonce: 0
        });

    function setUp() public {
        address o11y = address(new Observability());
        platform = new Platform(factory, o11y);
    }

    /// > [[[[[[[[[[[ Initializing ]]]]]]]]]]]

    function test_initialize() public {
        initialize();
    }

    function testRevert_InitlizerNotAuthorized() public {
        vm.expectRevert("UNATHORIZED_CALLER");
        platform.initialize(owner, initialPlatformData);
    }

    /// > [[[[[[[[[[[ Content Methods ]]]]]]]]]]]

    function test_AddContentDigestOwner() public {
        initialize();

        vm.prank(owner);
        platform.addContentDigest(sampleDigest);
    }

    function testAddContentDigestPublisher() public {
        initialize();

        vm.prank(owner);
        platform.setPublisher(publisher, true);

        vm.prank(publisher);
        platform.addContentDigest(sampleDigest);
    }

    function test_AddManyContentDigests() public {
        initialize();

        bytes32[] memory content = new bytes32[](2);
        content[0] = sampleDigest;
        content[1] = otherSampleDigest;

        vm.startPrank(owner);
        platform.addManyContentDigests(content);
        vm.stopPrank();
    }

    function testRevert_AddContentDigestNotOwnerOrPlatformOwner() public {
        initialize();

        vm.prank(owner);
        platform.addContentDigest(sampleDigest);

        vm.expectRevert("NOT_PUBLISHER_OR_PLATFORM_OWNER");
        platform.addContentDigest(sampleDigest);
    }

    function testRevert_AddContentDigestAlreadyPublished() public {
        initialize();

        vm.startPrank(owner);
        platform.addContentDigest(sampleDigest);
        platform.setPublisher(publisher, true);
        vm.stopPrank();

        vm.prank(publisher);
        vm.expectRevert("DIGEST_ALREADY_PUBLISHED");
        platform.addContentDigest(sampleDigest);
    }

    function test_RemoveContentDigestOwner() public {
        initialize();

        vm.startPrank(owner);
        platform.addContentDigest(sampleDigest);

        platform.removeContentDigest(sampleDigest);
        vm.stopPrank();
    }

    function test_RemoveContentDigestPublisher() public {
        initialize();

        vm.prank(owner);
        platform.setPublisher(publisher, true);

        vm.startPrank(publisher);
        platform.addContentDigest(sampleDigest);

        platform.removeContentDigest(sampleDigest);
        vm.stopPrank();
    }

    function test_RemoveManyContentDigests() public {
        initialize();

        bytes32[] memory content = new bytes32[](2);
        content[0] = sampleDigest;
        content[1] = otherSampleDigest;

        vm.startPrank(owner);
        platform.addManyContentDigests(content);

        platform.removeManyContentDigests(content);
        vm.stopPrank();
    }

    function testRevert_RemoveContentDigestNotOwnerOrPlatformOwner() public {
        initialize();

        vm.prank(owner);
        platform.addContentDigest(sampleDigest);

        vm.expectRevert("NOT_DIGEST_PUBLISHER_OR_OWNER");
        platform.removeContentDigest(sampleDigest);
    }

    function testRevert_RemoveContentDigestNotPublished() public {
        initialize();

        vm.prank(owner);
        vm.expectRevert("DIGEST_NOT_PUBLISHED");
        platform.removeContentDigest(sampleDigest);
    }

    /// > [[[[[[[[[[[ Platform Metadata Methods ]]]]]]]]]]]

    function test_SetPlatformMetadataDigestOwner() public {
        initialize();

        vm.prank(owner);
        platform.setPlatformMetadataDigest(sampleDigest);
    }

    function test_SetPlatformMetadataDigestMetadataManager() public {
        initialize();

        vm.prank(owner);
        platform.setMetadataManager(metadataManager, true);

        vm.prank(metadataManager);
        platform.setPlatformMetadataDigest(sampleDigest);
    }

    function testRevert_SetPlatformMetadataNotMetadataManagerOrOwner() public {
        initialize();

        vm.expectRevert("NOT_METADATA_MANAGER_OR_PLATFORM_OWNER");
        platform.setPlatformMetadataDigest(sampleDigest);
    }

    /// > [[[[[[[[[[[ Role Methods ]]]]]]]]]]]

    function test_SetMetadataManager() public {
        initialize();

        vm.prank(owner);
        platform.setMetadataManager(metadataManager, true);
        require(platform.allowedMetadataManagers(metadataManager));
    }

    function testRevert_SetMetadataManagerNotOwner() public {
        initialize();

        vm.expectRevert("caller is not the owner.");
        platform.setMetadataManager(metadataManager, true);
    }

    function test_SetMetadataManagers() public {
        initialize();

        address[] memory managers = new address[](2);
        managers[0] = metadataManager;
        managers[1] = otherMetadataManager;

        vm.prank(owner);
        platform.setManyMetadataManagers(managers, true);
        require(platform.allowedMetadataManagers(otherMetadataManager));
    }

    function testRevert_SetMetadataManagersNotOwner() public {
        initialize();

        address[] memory managers = new address[](2);
        managers[0] = metadataManager;
        managers[1] = otherMetadataManager;

        vm.expectRevert("caller is not the owner.");
        platform.setManyMetadataManagers(managers, true);
    }

    function test_SetPublisher() public {
        initialize();

        vm.prank(owner);
        platform.setPublisher(publisher, true);
        require(platform.allowedPublishers(publisher));
    }

    function testRevert_SetPublisherNotOwner() public {
        initialize();

        vm.expectRevert("caller is not the owner.");
        platform.setPublisher(publisher, true);
    }

    function test_SetPublishers() public {
        initialize();

        address[] memory publishers = new address[](2);
        publishers[0] = publisher;
        publishers[1] = otherPublisher;

        vm.prank(owner);
        platform.setManyPublishers(publishers, true);
        require(platform.allowedPublishers(otherPublisher));
    }

    function testRevert_SetPublishersNotOwner() public {
        initialize();

        address[] memory publishers = new address[](2);
        publishers[0] = publisher;
        publishers[1] = otherPublisher;

        vm.expectRevert("caller is not the owner.");
        platform.setManyPublishers(publishers, true);
    }

    /// > [[[[[[[[[[[ Internal Functions ]]]]]]]]]]]

    function initialize() internal {
        vm.prank(factory);
        platform.initialize(owner, initialPlatformData);
    }
}
