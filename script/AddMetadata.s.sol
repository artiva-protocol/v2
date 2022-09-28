// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/platform/PlatformFactory.sol";
import "../src/platform/interface/IPlatform.sol";
import "forge-std/console2.sol";

contract AddMetadata is Script {
    address constant OWNER = 0xa471C9508Acf13867282f36cfCe5c41D719ab78B;
    address clone = 0xe9603B18f135404a77EEb0EC44A8C5A7d68e1892;
    string content = '{ title: "Test Platform"}';

    function run() public {
        vm.startBroadcast();

        IPlatform(clone).setPlatformMetadata(content);

        vm.stopBroadcast();
    }
}
