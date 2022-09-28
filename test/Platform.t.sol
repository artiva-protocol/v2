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
        platform.initialize(owner, fowarder, getInitalPlatformData());
    }

    /// > [[[[[[[[[[[ Content Methods ]]]]]]]]]]]

    function test_AddContentOwner() public {
        initialize();

        vm.prank(owner);
        platform.addContent(sampleContent, owner);
    }

    function test_AddContentPublisher() public {
        initialize();

        vm.startPrank(owner);
        platform.grantRole(platform.CONTENT_PUBLISHER_ROLE(), publisher);
        vm.stopPrank();

        vm.startPrank(publisher);
        platform.addContent(sampleContent, publisher);
        vm.stopPrank();
    }

    function test_SetContentOwner() public {
        initialize();

        vm.startPrank(owner);
        platform.addContent(sampleContent, owner);
        platform.setContent(0, sampleContent);
        vm.stopPrank();
    }

    function test_SetContentPublisher() public {
        initialize();

        vm.startPrank(owner);
        platform.grantRole(platform.CONTENT_PUBLISHER_ROLE(), publisher);
        vm.stopPrank();

        vm.startPrank(publisher);
        platform.addContent(sampleContent, publisher);
        platform.setContent(0, sampleContent);
        vm.stopPrank();
    }

    function testRevert_SetContentOwnerSettingForAnother() public {
        initialize();

        vm.startPrank(owner);
        platform.grantRole(platform.CONTENT_PUBLISHER_ROLE(), publisher);
        platform.addContent(sampleContent, publisher);
        vm.stopPrank();

        vm.prank(publisher);
        platform.setContent(0, sampleContent);
    }

    function testRevert_AddContentNotAuthorized() public {
        initialize();

        vm.expectRevert("UNAUTHORIZED_ACCOUNT");
        platform.addContent(sampleContent, owner);
    }

    function testRevert_SetContentNotAuthorized() public {
        initialize();

        vm.expectRevert("UNAUTHORIZED_ACCOUNT");
        platform.setContent(0, sampleContent);
    }

    function testRevert_SetContentNoOwner() public {
        initialize();

        vm.expectRevert("NO_OWNER");
        vm.prank(owner);
        platform.setContent(0, sampleContent);
    }

    function testRevert_SetContentSenderNotOwner() public {
        initialize();

        vm.startPrank(owner);
        platform.grantRole(platform.CONTENT_PUBLISHER_ROLE(), publisher);
        platform.addContent(sampleContent, owner);
        vm.stopPrank();

        vm.expectRevert("SENDER_NOT_OWNER");
        vm.prank(publisher);
        platform.setContent(0, sampleContent);
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

    /// > [[[[[[[[[[[ Signature Methods ]]]]]]]]]]]

    function test_AddContentWithSig() public {
        initialize();

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            ownerPrivateKey,
            platform.getSigningMessage(owner)
        );

        platform.addContentWithSig(
            sampleContent,
            address(20),
            owner,
            abi.encodePacked(r, s, v)
        );
    }

    function test_SetContentWithSig() public {
        initialize();

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            ownerPrivateKey,
            platform.getSigningMessage(owner)
        );

        platform.addContentWithSig(
            sampleContent,
            owner,
            owner,
            abi.encodePacked(r, s, v)
        );

        platform.setContentWithSig(
            0,
            sampleContent,
            owner,
            abi.encodePacked(r, s, v)
        );
    }

    function test_SetPlatformMetadataWithSig() public {
        initialize();

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            ownerPrivateKey,
            platform.getSigningMessage(owner)
        );

        platform.setPlatformMetadataWithSig(
            sampleContent,
            owner,
            abi.encodePacked(r, s, v)
        );
    }

    function test_SetManyRolesWithSig() public {
        initialize();

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            ownerPrivateKey,
            platform.getSigningMessage(owner)
        );

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

        platform.setManyRolesWithSig(roles, owner, abi.encodePacked(r, s, v));

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

    function testRevert_AddContentWithSigBumpNonce() public {
        initialize();

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            ownerPrivateKey,
            platform.getSigningMessage(owner)
        );

        vm.prank(owner);
        platform.setSignatureNonce(1);

        vm.expectRevert("UNATHORIZED_SIGNATURE");
        platform.addContentWithSig(
            sampleContent,
            address(20),
            owner,
            abi.encodePacked(r, s, v)
        );
    }

    function testRevert_AddContentWithSigUnathorizedCaller() public {
        initialize();

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            unauthorizedAccountPrivateKey,
            platform.getSigningMessage(unauthorizedAccount)
        );

        vm.expectRevert("UNAUTHORIZED_ACCOUNT");
        platform.addContentWithSig(
            sampleContent,
            address(20),
            unauthorizedAccount,
            abi.encodePacked(r, s, v)
        );
    }

    function testRevert_SetContentWithSigUnathorizedCaller() public {
        initialize();

        vm.prank(owner);
        platform.addContent(sampleContent, owner);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            unauthorizedAccountPrivateKey,
            platform.getSigningMessage(unauthorizedAccount)
        );

        vm.expectRevert("UNAUTHORIZED_ACCOUNT");
        platform.setContentWithSig(
            0,
            sampleContent,
            unauthorizedAccount,
            abi.encodePacked(r, s, v)
        );
    }

    function testRevert_SetPlatformMetadataWithSigUnathorizedCaller() public {
        initialize();

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            unauthorizedAccountPrivateKey,
            platform.getSigningMessage(unauthorizedAccount)
        );

        vm.expectRevert("UNAUTHORIZED_ACCOUNT");
        platform.setPlatformMetadataWithSig(
            sampleContent,
            unauthorizedAccount,
            abi.encodePacked(r, s, v)
        );
    }

    function testRevert_SetManyRolesWithSigUnathorizedSigner() public {
        initialize();

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            unauthorizedAccountPrivateKey,
            platform.getSigningMessage(unauthorizedAccount)
        );

        IPlatform.RoleRequest[] memory roles = new IPlatform.RoleRequest[](1);

        roles[0] = IPlatform.RoleRequest({
            account: otherPublisher,
            role: platform.CONTENT_PUBLISHER_ROLE(),
            grant: true
        });

        vm.expectRevert("UNAUTHORIZED_ACCOUNT");
        platform.setManyRolesWithSig(
            roles,
            unauthorizedAccount,
            abi.encodePacked(r, s, v)
        );
    }

    /// > [[[[[[[[[[[ Internal Functions ]]]]]]]]]]]

    function initialize() internal {
        vm.prank(factory);
        platform.initialize(owner, fowarder, getInitalPlatformData());
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
                platformMetadataJSON: sampleContent,
                publishers: publishers,
                metadataManagers: managers,
                nonce: 0
            });
    }
}
