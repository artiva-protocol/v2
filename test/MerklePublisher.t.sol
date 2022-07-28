// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/platform/Platform.sol";
import "../src/publishers/MerklePublisher/MerklePublisher.sol";
import "../src/observability/Observability.sol";
import "openzeppelin/contracts/access/IAccessControl.sol";

contract MerklePublisherTest is Test {
    address factory = address(1);
    address owner = address(2);

    bytes32 sampleMerkleRoot = "W7_vCzkbZ_IJE9fsdoE4-trgeYpiWsds";
    bytes32 sampleLeavesDigest = "W7_vCzkbZ_IJE9fsdoE4-trgeYpiWsds";

    MerklePublisher publisher;
    Platform platform;

    function setUp() public {
        address o11y = address(new Observability());
        platform = new Platform(factory, o11y);
        publisher = new MerklePublisher("Artiva", "1");
    }

    function test_SetMerkleRoot() public {
        vm.mockCall(
            address(platform),
            abi.encodeWithSelector(IAccessControl.hasRole.selector),
            abi.encode(true)
        );

        publisher.setMerkleRoot(
            address(platform),
            sampleMerkleRoot,
            sampleLeavesDigest
        );
    }

    function testRevert_SetMerkleRootNotOwner() public {
        vm.expectRevert("MerklePublisher: NOT_AUTHORIZED");
        publisher.setMerkleRoot(
            address(platform),
            sampleMerkleRoot,
            sampleLeavesDigest
        );
    }
}
