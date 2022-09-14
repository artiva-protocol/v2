// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/platform/PlatformFactory.sol";
import "../src/platform/interface/IPlatform.sol";
import "forge-std/console2.sol";

contract AddRole is Script {
    address constant OWNER = 0xa471C9508Acf13867282f36cfCe5c41D719ab78B;
    address user = 0x04bfb0034F24E424489F566f32D1f57647469f9E;
    address clone = 0x4D44b433A999d24cd04188A30B42f9650441570F;
    bytes32 role = IPlatform(clone).CONTENT_PUBLISHER_ROLE();

    function run() public {
        vm.startBroadcast();

        IPlatform(clone).grantRole(role, user);

        vm.stopBroadcast();
    }
}
