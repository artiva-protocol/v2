// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/platform/PlatformFactory.sol";
import "../src/platform/interface/IPlatform.sol";
import "forge-std/console2.sol";

contract Sandbox is Script {
    address constant CLONE = 0xcEf3507A89FE87380586792245f9D52051bFBe54;
    address constant SIGNER = 0xa471C9508Acf13867282f36cfCe5c41D719ab78B;

    function run() public {
        vm.startBroadcast();
        bytes32 message = Platform(CLONE).getSigningMessage(SIGNER);
        console2.log("message:");
        console2.logBytes32(message);

        bytes32 structHash = Platform(CLONE).PUBLISH_AUTHORIZATION_TYPEHASH();
        console2.log("structHash:");
        console2.logBytes32(structHash);

        console2.logBytes32(
            keccak256(
                "PublishAuthorization(string message,address publishingKey,uint256 nonce)"
            )
        );
        vm.stopBroadcast();
    }
}
