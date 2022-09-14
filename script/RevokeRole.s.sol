// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/platform/PlatformFactory.sol";
import "../src/platform/interface/IPlatform.sol";
import "forge-std/console2.sol";

contract RevokeRole is Script {
    address constant OWNER = 0xa471C9508Acf13867282f36cfCe5c41D719ab78B;
    address constant OTHER_ACCOUNT1 =
        0x04bfb0034F24E424489F566f32D1f57647469f9E;
    address constant OTHER_ACCOUNT2 =
        0x14BfB0034F24E424489f566F32D1F57647469f9e;
    address constant OTHER_ACCOUNT3 =
        0x24bFb0034F24E424489f566F32d1f57647469f9e;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    bytes32 public constant CONTENT_PUBLISHER_ROLE =
        keccak256("CONTENT_PUBLISHER_ROLE");

    bytes32 public constant METADATA_MANAGER_ROLE =
        keccak256("METADATA_MANAGER_ROLE");

    address clone = 0x4D44b433A999d24cd04188A30B42f9650441570F;

    function run() public {
        vm.startBroadcast();

        IPlatform(clone).revokeRole(DEFAULT_ADMIN_ROLE, OTHER_ACCOUNT1);
        IPlatform(clone).revokeRole(CONTENT_PUBLISHER_ROLE, OTHER_ACCOUNT2);
        IPlatform(clone).revokeRole(METADATA_MANAGER_ROLE, OTHER_ACCOUNT3);

        vm.stopBroadcast();
    }
}
