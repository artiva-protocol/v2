// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/platform/Platform.sol";
import "../src/platform/PlatformFactory.sol";
import "../src/observability/Observability.sol";
import "@opengsn/contracts/src/forwarder/Forwarder.sol";

contract PlatformTest is Test {
    PlatformFactory factory;

    address internal owner;
    uint256 internal ownerPrivateKey;

    function setUp() public {
        ownerPrivateKey = 0xA11CE;
        owner = vm.addr(ownerPrivateKey);
        address fowarder = address(new Forwarder());
        factory = new PlatformFactory(owner, fowarder);
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

    function test_CreateTwo() public {
        factory.create(getInitalPlatformData());
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
                platformMetadataURI: "",
                publishers: publishers,
                metadataManagers: managers,
                initalContentURIs: new string[](0),
                nonce: 0
            });
    }
}
