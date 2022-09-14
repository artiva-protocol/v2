// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/platform/PlatformFactory.sol";
import "../src/platform/interface/IPlatform.sol";
import "forge-std/console2.sol";

contract AddContent is Script {
    address constant OWNER = 0xa471C9508Acf13867282f36cfCe5c41D719ab78B;
    address user = 0x04bfb0034F24E424489F566f32D1f57647469f9E;
    address clone = 0x29aBA49Ec49a070D5143FE93Fa0f6145a7Ab7CA8;
    string content = "https://www.google2.com";

    function run() public {
        vm.startBroadcast();

        //IPlatform(clone).addContent(content, OWNER);
        IPlatform(clone).setContent(1, content);

        vm.stopBroadcast();
    }
}
