// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/platform/Platform.sol";
import "../src/platform/PlatformFactory.sol";
import "../src/observability/Observability.sol";

contract PlatformTest is Test {
    PlatformFactory factory;

    address internal owner;
    uint256 internal ownerPrivateKey;

    function setUp() public {
        ownerPrivateKey = 0xA11CE;
        owner = vm.addr(ownerPrivateKey);
        factory = new PlatformFactory(owner, "Artiva", "1");
    }

    function test_SetImplementation() public {
        vm.prank(owner);
        factory.setImplementation(address(2));
    }

    function testRevert_SetImplementationUnauthorizedCaller() public {
        vm.expectRevert("caller is not the owner.");
        factory.setImplementation(address(2));
    }

    function test_Create() public {
        factory.create(getInitalPlatformData());
    }

    function test_CreateWithSig() public {
        IPlatform.PlatformData memory platformData = getInitalPlatformData();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            ownerPrivateKey,
            factory.getSalt(owner, platformData)
        );
        factory.createWithSignature(owner, platformData, v, r, s);
    }

    function testRevert_CreateWithSigAddressZero() public {
        IPlatform.PlatformData memory platformData = getInitalPlatformData();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            ownerPrivateKey,
            factory.getSalt(address(0), platformData)
        );
        vm.expectRevert("CANNOT_VALIDATE");
        factory.createWithSignature(address(0), platformData, v, r, s);
    }

    function testRevert_CreateWithSigInvalidOwner() public {
        IPlatform.PlatformData memory platformData = getInitalPlatformData();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            ownerPrivateKey,
            factory.getSalt(address(1), platformData)
        );
        vm.expectRevert("SIGNATURE_ERROR");
        factory.createWithSignature(address(1), platformData, v, r, s);
    }

    function testRevert_CreateWithSigInvalidPlatformData() public {
        IPlatform.PlatformData memory platformData = getInitalPlatformData();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            ownerPrivateKey,
            factory.getSalt(owner, platformData)
        );

        platformData.nonce = 1;

        vm.expectRevert("SIGNATURE_ERROR");
        factory.createWithSignature(owner, platformData, v, r, s);
    }

    function testRevert_CreateWithSigAlreadyUsedSignature() public {
        IPlatform.PlatformData memory platformData = getInitalPlatformData();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            ownerPrivateKey,
            factory.getSalt(owner, platformData)
        );

        factory.createWithSignature(owner, platformData, v, r, s);

        vm.expectRevert("ERC1167: create2 failed");
        factory.createWithSignature(owner, platformData, v, r, s);
    }

    function getInitalPlatformData()
        internal
        pure
        returns (IPlatform.PlatformData memory)
    {
        address[] memory publishers = new address[](1);
        address[] memory managers = new address[](1);

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
