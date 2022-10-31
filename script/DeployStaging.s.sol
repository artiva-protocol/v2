// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/platform/PlatformFactory.sol";
import "../src/platform/interface/IPlatform.sol";
import "forge-std/console2.sol";

contract Deploy is Script {
    address constant OWNER = 0xa471C9508Acf13867282f36cfCe5c41D719ab78B;
    address constant USER = 0x04bfb0034F24E424489F566f32D1f57647469f9E;

    function run() public {
        vm.startBroadcast();
        PlatformFactory factory = new PlatformFactory(OWNER);
        address clone = deployPlatform(address(factory));

        vm.stopBroadcast();

        console2.log("factory:");
        console2.log(address(factory));

        console2.log("o11y:");
        console2.log(factory.o11y());

        console2.log("clone:");
        console2.log(clone);
    }

    function deployPlatform(address factory) internal returns (address) {
        IPlatform.RoleRequest[] memory roles = new IPlatform.RoleRequest[](2);
        roles[0] = IPlatform.RoleRequest({
            role: IPlatform.Role.ADMIN,
            account: OWNER
        });
        roles[1] = IPlatform.RoleRequest({
            role: IPlatform.Role.MANAGER,
            account: USER
        });
        return PlatformFactory(factory).create("", roles);
    }
}
