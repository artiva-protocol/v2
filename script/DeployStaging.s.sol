// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/platform/PlatformFactory.sol";

contract Deploy is Script {
    address constant OWNER = 0xa471C9508Acf13867282f36cfCe5c41D719ab78B;
    address constant FORWARDER = 0x7A95fA73250dc53556d264522150A940d4C50238;

    function run() public {
        vm.startBroadcast();
        new PlatformFactory(OWNER, FORWARDER);
        vm.stopBroadcast();
    }
}
