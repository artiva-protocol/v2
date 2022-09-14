// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/paymasters/ArtivaPaymaster.sol";
import "forge-std/console2.sol";

contract Deploy is Script {
    address constant signer = 0x04bfb0034F24E424489F566f32D1f57647469f9E;

    /*

    function run() public {
        vm.startBroadcast();
        ArtivaPaymaster factory = new ArtivaPaymaster(target, FORWARDER);
        address clone = factory.create(getInitalPlatformData());

        vm.stopBroadcast();

        console2.log("paymaster:");
        console2.log(address(factory));
    }
    */
}
