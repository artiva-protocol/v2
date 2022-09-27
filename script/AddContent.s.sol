// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/platform/PlatformFactory.sol";
import "../src/platform/interface/IPlatform.sol";
import "forge-std/console2.sol";

contract AddContent is Script {
    address constant OWNER = 0xa471C9508Acf13867282f36cfCe5c41D719ab78B;
    address constant CLONE = 0x95060Cc429e7A61f8302D1B63ed5c4087Ae397b7;
    string content =
        '[{"id":"ETHEREUM:700:7","contentJSON":"{ contract: 700 id: 7}"},{"id":"ETHEREUM:800:8","contentJSON":"{ conttract: 800 id: 8}","type":"nft"}]';

    function run() public {
        vm.startBroadcast();
        //IPlatform(CLONE).addContent(content, OWNER);
        IPlatform(CLONE).setContent(0, content);

        vm.stopBroadcast();
    }
}
