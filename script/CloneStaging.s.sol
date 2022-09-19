// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/platform/PlatformFactory.sol";
import "../src/platform/interface/IPlatform.sol";
import "forge-std/console2.sol";

contract Clone is Script {
    address constant OWNER = 0xa471C9508Acf13867282f36cfCe5c41D719ab78B;
    address constant USER = 0x1d14d9e297DfbcE003f5A8EbcF8cBa7fAEe70B91;
    address constant FORWARDER = 0x7A95fA73250dc53556d264522150A940d4C50238;
    address constant FACTORY = 0x2fDbfC9e292EEc6f782F13Ae5c1fc868848D86Bd;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    bytes32 public constant CONTENT_PUBLISHER_ROLE =
        keccak256("CONTENT_PUBLISHER_ROLE");

    bytes32 public constant METADATA_MANAGER_ROLE =
        keccak256("METADATA_MANAGER_ROLE");

    function run() public {
        vm.startBroadcast();
        address clone = PlatformFactory(FACTORY).create(
            getInitalPlatformData()
        );

        vm.stopBroadcast();

        console2.log("clone:");
        console2.log(clone);
    }

    function getInitalPlatformData()
        internal
        pure
        returns (IPlatform.PlatformData memory)
    {
        address[] memory publishers = new address[](2);
        address[] memory managers = new address[](2);
        string[] memory initalContentURIs = new string[](0);

        publishers[0] = OWNER;
        publishers[1] = USER;

        managers[0] = OWNER;
        managers[1] = USER;

        return
            IPlatform.PlatformData({
                platformMetadataURI: "",
                publishers: publishers,
                metadataManagers: managers,
                initalContentURIs: initalContentURIs,
                nonce: 0
            });
    }
}
