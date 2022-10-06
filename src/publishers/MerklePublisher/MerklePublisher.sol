// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "../../platform/interface/IPlatform.sol";
import "./interface/IMerklePublisher.sol";

contract MerklePublisher is IMerklePublisher {
    mapping(address => bytes32) public platformToMerkleRoot;
    mapping(address => string) public platformToLeavesURI;

    /// > [[[[[[[[[[[ Merkle root functions ]]]]]]]]]]]

    function setMerkleRoot(
        address platform,
        bytes32 merkleRoot,
        string calldata leavesURI
    ) external {
        require(
            IAccessControl(platform).hasRole(
                IPlatform(platform).getDefaultAdminRole(),
                msg.sender
            ),
            "MerklePublisher: NOT_AUTHORIZED"
        );
        platformToMerkleRoot[platform] = merkleRoot;
        platformToLeavesURI[platform] = leavesURI;
    }

    /// > [[[[[[[[[[[ Publish functions ]]]]]]]]]]]

    function publish(
        address platform,
        bytes32[] calldata proof,
        string[] calldata contents
    ) external {
        _verifyMerkleRoot(msg.sender, proof, platform);
        IPlatform(platform).addContents(contents, msg.sender);
    }

    /// > [[[[[[[[[[[ Internal functions ]]]]]]]]]]]

    function _verifyMerkleRoot(
        address owner,
        bytes32[] calldata proof,
        address platform
    ) internal view {
        bytes32 leaf = keccak256(abi.encodePacked(owner));
        require(
            MerkleProof.verifyCalldata(
                proof,
                platformToMerkleRoot[platform],
                leaf
            ),
            "MerklePublisher: INVALID_PROOF"
        );
    }
}
