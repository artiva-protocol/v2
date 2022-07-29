// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/platform/PlatformFactory.sol";

contract Deploy is Script {
    address constant OWNER = 0xa471C9508Acf13867282f36cfCe5c41D719ab78B;
    address constant FORWARDER = 0x7A95fA73250dc53556d264522150A940d4C50238;

    function run() public {
        vm.startBroadcast();
        PlatformFactory factory = new PlatformFactory(OWNER, FORWARDER);
        factory.create(getInitalPlatformData());
        vm.stopBroadcast();
    }

    function getInitalPlatformData()
        internal
        pure
        returns (IPlatform.PlatformData memory)
    {
        address[] memory publishers = new address[](1);
        address[] memory managers = new address[](1);
        bytes32[] memory initalContent = new bytes32[](0);
        publishers[0] = OWNER;
        managers[0] = OWNER;
        initalContent[0] = "W7_vCzkbZ_IJE9fsdoE4-trgeYpiWsds";

        return
            IPlatform.PlatformData({
                platformMetadataDigest: "W7_vCzkbZ_IJE9fsdoE4-trgeYpiWsds",
                publishers: publishers,
                metadataManagers: managers,
                initalContent: initalContent,
                nonce: 0
            });
    }
}
