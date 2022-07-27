// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/platform/Platform.sol";
import "../src/observability/Observability.sol";

contract PlatformTest is Test {
    Platform public platform;
    address factory = address(1);
    address owner = address(2);
    address publisher = address(3);
    address otherPublisher = address(4);
    address metadataManager = address(5);
    address otherMetadataManager = address(6);
    address unauthorizedAccount = address(7);
    bytes32 sampleDigest = "W7_vCzkbZ_IJE9fsdoE4-trgeYpiWsds";
    bytes32 otherSampleDigest = "B8_vCzkbZ_IJE9fsdoE4-trgeYpiWsds";

    function setUp() public {
        address o11y = address(new Observability());
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

    function test_AddContentDigestOwner() public {
        initialize();

        vm.prank(owner);
        platform.addContentDigest(sampleDigest);
    }

    function testAddContentDigestPublisher() public {
        initialize();

        vm.startPrank(owner);
        platform.grantRole(platform.CONTENT_PUBLISHER_ROLE(), publisher);
        vm.stopPrank();

        vm.startPrank(publisher);
        platform.addContentDigest(sampleDigest);
        vm.stopPrank();
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

        vm.prank(unauthorizedAccount);
        vm.expectRevert("UNAUTHORIZED_CALLER");
        platform.addContentDigest(sampleDigest);
    }

    function testRevert_AddContentDigestAlreadyPublished() public {
        initialize();

        vm.startPrank(owner);
        platform.addContentDigest(sampleDigest);
        platform.grantRole(platform.CONTENT_PUBLISHER_ROLE(), publisher);
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

        vm.startPrank(owner);
        platform.grantRole(platform.CONTENT_PUBLISHER_ROLE(), publisher);
        vm.stopPrank();

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

        vm.expectRevert("NOT_DIGEST_PUBLISHER");
        platform.removeContentDigest(sampleDigest);
    }

    function testRevert_RemoveContentDigestNotPublished() public {
        initialize();

        vm.prank(owner);
        vm.expectRevert("NOT_DIGEST_PUBLISHER");
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

        vm.startPrank(owner);
        platform.grantRole(platform.METADATA_MANAGER_ROLE(), metadataManager);
        vm.stopPrank();

        vm.startPrank(metadataManager);
        platform.setPlatformMetadataDigest(sampleDigest);
        vm.stopPrank();
    }

    function testRevert_SetPlatformMetadataNotMetadataManagerOrOwner() public {
        initialize();
        vm.prank(unauthorizedAccount);
        vm.expectRevert("UNAUTHORIZED_CALLER");
        platform.setPlatformMetadataDigest(sampleDigest);
    }

    /// > [[[[[[[[[[[ Internal Functions ]]]]]]]]]]]

    function initialize() internal {
        vm.prank(factory);
        platform.initialize(owner, getInitalPlatformData());
    }

    function getInitalPlatformData()
        internal
        returns (IPlatform.PlatformData memory)
    {
        address[] memory publishers = new address[](1);
        publishers[0] = owner;

        address[] memory managers = new address[](1);
        managers[0] = owner;

        return
            IPlatform.PlatformData({
                platformMetadataDigest: "",
                publishers: publishers,
                metadataManagers: managers,
                initalContent: new bytes32[](0),
                nonce: 0
            });
    }
}
