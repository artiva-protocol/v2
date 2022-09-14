// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/platform/PlatformFactory.sol";
import "../src/platform/interface/IPlatform.sol";
import "forge-std/console2.sol";

contract AddMetadata is Script {
    address constant OWNER = 0xa471C9508Acf13867282f36cfCe5c41D719ab78B;
    address user = 0x04bfb0034F24E424489F566f32D1f57647469f9E;
    address clone = 0xB792786e3E97B199a1AADed9AeAbD455D977240F;
    string content = "https://www.google2.com";

    function run() public {
        vm.startBroadcast();

        //IPlatform(clone).addContent(content, OWNER);
        IPlatform(clone).setPlatformMetadataURI(content);

        vm.stopBroadcast();
    }
}
