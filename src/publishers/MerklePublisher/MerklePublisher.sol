// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "../../platform/interface/IPlatform.sol";
import "./interface/IMerklePublisher.sol";
import "@opengsn/contracts/src/ERC2771Recipient.sol";

contract MerklePublisher is IMerklePublisher, ERC2771Recipient {
    mapping(address => bytes32) public platformToMerkleRoot;
    mapping(address => string) public platformToLeavesURI;

    /// > [[[[[[[[[[[ Merkle root functions ]]]]]]]]]]]

    constructor(address forwarder) {
        _setTrustedForwarder(forwarder);
    }

    function setMerkleRoot(
        address platform,
        bytes32 merkleRoot,
        string calldata leavesURI
    ) external {
        require(
            IAccessControl(platform).hasRole(
                IPlatform(platform).getDefaultAdminRole(),
                _msgSender()
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
        string calldata contentURI
    ) external {
        _verifyMerkleRoot(_msgSender(), proof, platform);
        IPlatform(platform).addContent(contentURI, _msgSender());
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
