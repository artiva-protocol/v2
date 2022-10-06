// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/platform/PlatformFactory.sol";
import "@opengsn/contracts/src/forwarder/Forwarder.sol";

contract Deploy is Script {
    address constant OWNER = 0xa471C9508Acf13867282f36cfCe5c41D719ab78B;

    function run() public {
        vm.startBroadcast();
        new PlatformFactory(OWNER);
        vm.stopBroadcast();
    }
}
