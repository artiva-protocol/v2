// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {Platform} from "../src/platforms/Platform.sol";
import {Observability} from "../src/observability/Observability.sol";

contract PlatformTest is Test {

    Platform public platform;
    address factory = 0x0000000000000000000000000000000000000001;
    address owner = 0x0000000000000000000000000000000000000002;
    address publisher = 0x0000000000000000000000000000000000000003;
    address otherPublisher = 0x0000000000000000000000000000000000000004;
    address metadataManager = 0x0000000000000000000000000000000000000005;
    address otherMetadataManager = 0x0000000000000000000000000000000000000006;
    bytes32 sampleDigest = "W7_vCzkbZ_IJE9fsdoE4-trgeYpiWsds";

    function setUp() public {
        address o11y = address(new Observability());
        platform = new Platform(factory, o11y);
    }

    /// > [[[[[[[[[[[ Initializing ]]]]]]]]]]]

    function test_initilize() public {
        initilize();
    }

    function testRevert_InitlizerNotAuthorized() public {
        vm.expectRevert("UNATHORIZED_CALLER");
        platform.initilize(owner);
    }

    /// > [[[[[[[[[[[ Content Methods ]]]]]]]]]]]

    function testGas_AddContentCollection(uint16 size) public {
        vm.assume(size > 5 && size < 200);
        initilize();

        vm.prank(owner);
        addContentCollection(size);
    }

    function test_AddContentCollectionOwner() public {
        initilize();

        vm.prank(owner);
        addContentCollection(20);
    }

    function test_AddContentCollectionPublisher() public {
        initilize();

        vm.prank(owner);
        platform.setPublisher(publisher, true);

        vm.prank(publisher);
        addContentCollection(20);
    }

    function testRevert_AddContentCollectionNotOwnerOrPublisher() public {
        initilize();
        vm.expectRevert("NOT_PUBLISHER_OR_PLATFORM_OWNER");
        addContentCollection(20);
    }

    function test_SetContentCollectionOwner() public {
        initilize();

        vm.startPrank(owner);
        (uint256 contentCollectionId) = addContentCollection(20);
        setContentCollection(contentCollectionId, 20);
        vm.stopPrank();
    }

    function test_SetContentCollectionPublisher() public {
        initilize();

        vm.prank(owner);
        platform.setPublisher(publisher, true);

        vm.startPrank(publisher);
        (uint256 contentCollectionId) = addContentCollection(20);
        setContentCollection(contentCollectionId, 20);
        vm.stopPrank();
    }

    function testRevert_SetContentCollectionNotOwnerOrPlatformOwner() public {
        initilize();

        vm.prank(owner);
        (uint256 contentCollectionId) = addContentCollection(20);

        vm.expectRevert("NOT_CONTENT_OWNER_OR_PLATFORM_OWNER");
        setContentCollection(contentCollectionId, 20);
    }

    function testRevert_SetContentCollectionIdDoesNotExist() public {
        initilize();
        
        vm.prank(owner);
        vm.expectRevert("CONTENT_SET_ID_DOES_NOT_EXIST");
        setContentCollection(0, 20);
    }

    function test_SetContentDigestOwner() public {
        initilize();

        vm.startPrank(owner);
        (uint256 contentCollectionId) = addContentCollection(20);
        platform.setContentDigest(contentCollectionId, 0, sampleDigest);
        vm.stopPrank();
    }

    function test_SetContentDigestPublisher() public {
        initilize();

        vm.prank(owner);
        platform.setPublisher(publisher, true);

        vm.startPrank(publisher);
        (uint256 contentCollectionId) = addContentCollection(20);
        platform.setContentDigest(contentCollectionId, 0, sampleDigest);
        vm.stopPrank();
    }

    function testRevert_SetContentDigestNotOwnerOrPlatformOwner() public {
        initilize();

        vm.prank(owner);
        (uint256 contentCollectionId) = addContentCollection(20);

        vm.expectRevert("NOT_CONTENT_OWNER_OR_PLATFORM_OWNER");
        platform.setContentDigest(contentCollectionId, 0, sampleDigest);
    }

    function testRevert_SetContentDigestIdDoesNotExist() public {
        initilize();
        
        vm.prank(owner);
        vm.expectRevert("CONTENT_SET_ID_DOES_NOT_EXIST");
        platform.setContentDigest(0, 0, sampleDigest);
    }

    function testRevert_SetContentDigestIndexDoesNotExist() public {
        initilize();

        vm.startPrank(owner);
        (uint256 contentCollectionId) = addContentCollection(20);

        vm.expectRevert("CONTENT_INDEX_DOES_NOT_EXIST");
        platform.setContentDigest(contentCollectionId, 21, sampleDigest);
        vm.stopPrank();
    }

    function test_DeleteContentCollectionOwner() public {
        initilize();

        vm.startPrank(owner);
        (uint256 contentCollectionId) = addContentCollection(20);

        platform.deleteContentCollection(contentCollectionId);
        vm.stopPrank();
    }

    function test_DeleteContentCollectionPublisher() public {
        initilize();

        vm.prank(owner);
        platform.setPublisher(publisher, true);

        vm.startPrank(publisher);
        (uint256 contentCollectionId) = addContentCollection(20);
        platform.deleteContentCollection(contentCollectionId);
        vm.stopPrank();
    }

    function testRevert_DeleteContentCollectionNotOwnerOrPlatformOwner() public {
        initilize();

        vm.prank(owner);
        (uint256 contentCollectionId) = addContentCollection(20);

        vm.expectRevert("NOT_CONTENT_OWNER_OR_PLATFORM_OWNER");
        platform.deleteContentCollection(contentCollectionId);
    }

    function testRevert_DeleteContentCollectionIdDoesNotExist() public {
        initilize();
        
        vm.prank(owner);
        vm.expectRevert("CONTENT_SET_ID_DOES_NOT_EXIST");
        platform.deleteContentCollection(0);
    }

    function test_DeleteContentDigestOwner() public {
        initilize();

        vm.startPrank(owner);
        (uint256 contentCollectionId) = addContentCollection(20);

        platform.deleteContentDigest(contentCollectionId, 0);
        vm.stopPrank();
    }

    function test_DeleteContentDigestPublisher() public {
        initilize();

        vm.prank(owner);
        platform.setPublisher(publisher, true);

        vm.startPrank(publisher);
        (uint256 contentCollectionId) = addContentCollection(20);
        platform.deleteContentDigest(contentCollectionId, 0);
        vm.stopPrank();
    }

    function testRevert_DeleteContentDigestNotOwnerOrPlatformOwner() public {
        initilize();

        vm.prank(owner);
        (uint256 contentCollectionId) = addContentCollection(20);

        vm.expectRevert("NOT_CONTENT_OWNER_OR_PLATFORM_OWNER");
        platform.deleteContentDigest(contentCollectionId, 0);
    }

    function testRevert_DeleteContentDigestIdDoesNotExist() public {
        initilize();
        
        vm.prank(owner);
        vm.expectRevert("CONTENT_SET_ID_DOES_NOT_EXIST");
        platform.deleteContentDigest(0, 0);
    }

    function testRevert_DeleteContentDigestIndexDoesNotExist() public {
        initilize();

        vm.startPrank(owner);
        (uint256 contentCollectionId) = addContentCollection(20);

        vm.expectRevert("CONTENT_INDEX_DOES_NOT_EXIST");
        platform.deleteContentDigest(contentCollectionId, 21);
        vm.stopPrank();
    }

    function test_GetAllContentDigests() public {
        initilize();

        vm.startPrank(owner);
        addContentCollection(20);
        addContentCollection(20);
        vm.stopPrank();
        bytes32[] memory digests = platform.getAllContentDigests();
        require(digests.length == 40);
    }

    function test_GetAllContentCollections() public {
        initilize();

        vm.startPrank(owner);
        addContentCollection(20);
        addContentCollection(20);
        vm.stopPrank();
        bytes32[][] memory sets = platform.getContentCollections();
        require(sets.length == 2);
    }

    function test_GetAllContentCollectionById() public {
        initilize();

        vm.startPrank(owner);
        addContentCollection(20);
        vm.stopPrank();
        bytes32[] memory set = platform.getContentCollectionById(0);
        require(set.length == 20);
    }

    /// > [[[[[[[[[[[ Platform Metadata Methods ]]]]]]]]]]]

    function test_SetPlatformMetadataDigestOwner() public {
        initilize();

        vm.prank(owner);
        platform.setPlatformMetadataDigest(sampleDigest);
    }

    function test_SetPlatformMetadataDigestMetadataManager() public {
        initilize();

        vm.prank(owner);
        platform.setMetadataManager(metadataManager, true);

        vm.prank(metadataManager);
        platform.setPlatformMetadataDigest(sampleDigest);
    }

    function testRevert_SetPlatformMetadataNotMetadataManagerOrOwner() public {
        initilize();

        vm.expectRevert("NOT_METADATA_MANAGER_OR_PLATFORM_OWNER");
        platform.setPlatformMetadataDigest(sampleDigest);
    }

    /// > [[[[[[[[[[[ Role Methods ]]]]]]]]]]]

    function test_SetMetadataManager() public {
        initilize();

        vm.prank(owner);
        platform.setMetadataManager(metadataManager, true);
        require(platform.allowedMetadataManagers(metadataManager));
    }

    function testRevert_SetMetadataManagerNotOwner() public {
        initilize();

        vm.expectRevert("Ownable: caller is not the owner");
        platform.setMetadataManager(metadataManager, true);
    }

    function test_SetMetadataManagers() public {
        initilize();

        address[] memory managers = new address[](2);
        managers[0] = metadataManager;
        managers[1] = otherMetadataManager;

        vm.prank(owner);
        platform.setMetadataManagers(managers, true);
        require(platform.allowedMetadataManagers(otherMetadataManager));
    }

    function testRevert_SetMetadataManagersNotOwner() public {
        initilize();

        address[] memory managers = new address[](2);
        managers[0] = metadataManager;
        managers[1] = otherMetadataManager;

        vm.expectRevert("Ownable: caller is not the owner");
        platform.setMetadataManagers(managers, true);
    }

    function test_SetPublisher() public {
        initilize();

        vm.prank(owner);
        platform.setPublisher(publisher, true);
        require(platform.allowedPublishers(publisher));
    }

    function testRevert_SetPublisherNotOwner() public {
        initilize();

        vm.expectRevert("Ownable: caller is not the owner");
        platform.setPublisher(publisher, true);
    }

    function test_SetPublishers() public {
        initilize();

        address[] memory publishers = new address[](2);
        publishers[0] = publisher;
        publishers[1] = otherPublisher;

        vm.prank(owner);
        platform.setPublishers(publishers, true);
        require(platform.allowedPublishers(otherPublisher));
    }

    function testRevert_SetPublishersNotOwner() public {
        initilize();

        address[] memory publishers = new address[](2);
        publishers[0] = publisher;
        publishers[1] = otherPublisher;

        vm.expectRevert("Ownable: caller is not the owner");
        platform.setPublishers(publishers, true);
    }

    /// > [[[[[[[[[[[ Internal Functions ]]]]]]]]]]]

    function initilize() internal {
        vm.prank(factory);
        platform.initilize(owner);
    }

    function addContentCollection(uint16 size) internal returns(uint256) {
        return platform.addContentCollection(getContentCollection(size));
    }

    function setContentCollection(uint256 contentCollectionId, uint16 size) internal {
        platform.setContentCollection(contentCollectionId, getContentCollection(size));
    }

    function getContentCollection(uint16 size) internal view returns (bytes32[] memory) {
        bytes32[] memory content = new bytes32[](size);
        for(uint16 i = 0; i < size; i++) {
            content[i] = sampleDigest;
        }
        return content;
    }
}
