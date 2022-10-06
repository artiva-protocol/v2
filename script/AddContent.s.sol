// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/platform/PlatformFactory.sol";
import "../src/platform/interface/IPlatform.sol";
import "forge-std/console2.sol";

contract AddContent is Script {
    address constant OWNER = 0xa471C9508Acf13867282f36cfCe5c41D719ab78B;
    address constant CLONE = 0x007637cDa7516bC86053a239b04A83AbD72d1d7C;
    string rawContent =
        '{"id":"ETHEREUM:1000:8","contentJSON":"{ contract: 1000 id: 8}","type":"nft"}';
    string rawContent2 =
        '{"id":"ETHEREUM:2000:8","contentJSON":"{ contract: 2000 id: 8}","type":"nft"}';

    function run() public {
        vm.startBroadcast();

        /*
        string[] memory contents = new string[](2);
        contents[0] = rawContent;
        contents[1] = rawContent2;

        IPlatform(CLONE).addContents(contents, OWNER);
        */

        IPlatform.SetContentRequest[]
            memory reqs = new IPlatform.SetContentRequest[](2);

        reqs[0] = IPlatform.SetContentRequest({
            contentId: 0,
            content: rawContent
        });

        reqs[1] = IPlatform.SetContentRequest({
            contentId: 1,
            content: rawContent2
        });

        IPlatform(CLONE).setContents(reqs);

        vm.stopBroadcast();
    }
}
