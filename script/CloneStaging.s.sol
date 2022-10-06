// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/platform/PlatformFactory.sol";
import "../src/platform/interface/IPlatform.sol";
import "forge-std/console2.sol";

contract Clone is Script {
    address constant OWNER = 0xa471C9508Acf13867282f36cfCe5c41D719ab78B;
    address constant USER = 0x333d0EBc54707c0a9D92caC749B3094c28a0E111;
    address constant FACTORY = 0x251B9B231845A3772b887061dCc1c411F297aeA8;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    bytes32 public constant CONTENT_PUBLISHER_ROLE =
        keccak256("CONTENT_PUBLISHER_ROLE");

    bytes32 public constant METADATA_MANAGER_ROLE =
        keccak256("METADATA_MANAGER_ROLE");

    function run() public {
        vm.startBroadcast();
        address clone = deployPlatform();
        vm.stopBroadcast();

        console2.log("clone:");
        console2.log(clone);
    }

    function deployPlatform() internal returns (address) {
        address[] memory publishers = new address[](2);
        address[] memory managers = new address[](2);

        publishers[0] = OWNER;
        publishers[1] = USER;

        managers[0] = OWNER;
        managers[1] = USER;

        return PlatformFactory(FACTORY).create("", publishers, managers);
    }
}
