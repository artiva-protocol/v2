// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/platform/PlatformFactory.sol";
import "forge-std/console2.sol";

contract GetObservability is Script {
    address constant platform = 0x735117197CA0E8B09Ffef2fc214dBa2776300CCa;

    function run() public {
        address o11y = Platform(platform).o11y();
        console2.log(o11y);
    }
}
