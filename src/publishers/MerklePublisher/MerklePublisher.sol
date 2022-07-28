// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "openzeppelin/contracts/access/IAccessControl.sol";
import "../../platform/interface/IPlatform.sol";
import "./interface/IMerklePublisher.sol";
import "openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

contract MerklePublisher is IMerklePublisher, EIP712 {
    mapping(address => bytes32) platformToMerkleRoot;
    mapping(address => bytes32) platformToLeavesDigest;
    mapping(bytes32 => bool) signatureDigestUsed;

    bytes32 public constant PUBLISH_TYPEHASH =
        keccak256(
            "Publish(address owner.address platform,bytes32[] proof,bytes32 contentDigest,uint256 nonce)"
        );

    bytes32 public constant SET_MERKLE_ROOT_TYPEHASH =
        keccak256(
            "SetMerkleRoot(address account,address platform,bytes32 merkleRoot,bytes32 leavesDigest,uint256 nonce)"
        );

    constructor(string memory domainName, string memory domainVersion)
        EIP712(domainName, domainVersion)
    {}

    /// > [[[[[[[[[[[ View functions ]]]]]]]]]]]

    function getPublishDataDigest(address owner, PublishData calldata data)
        external
        view
        returns (bytes32)
    {
        return _getPublishDataDigest(owner, data);
    }

    function getMerkleRootDigest(address owner, MerkleRootData calldata data)
        external
        view
        returns (bytes32)
    {
        return _getMerkleRootDigest(owner, data);
    }

    /// > [[[[[[[[[[[ Merkle root functions ]]]]]]]]]]]

    function setMerkleRoot(
        address platform,
        bytes32 merkleRoot,
        bytes32 leavesDigest
    ) external {
        require(
            IAccessControl(platform).hasRole(
                IPlatform(platform).getDefaultAdminRole(),
                msg.sender
            ),
            "MerklePublisher: NOT_AUTHORIZED"
        );
        platformToMerkleRoot[platform] = merkleRoot;
        platformToLeavesDigest[platform] = leavesDigest;
    }

    function setMerkleRootWithSig(
        address account,
        MerkleRootData calldata data,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(
            IAccessControl(data.platform).hasRole(
                IPlatform(data.platform).getDefaultAdminRole(),
                account
            ),
            "MerklePublisher: NOT_AUTHORIZED"
        );

        bytes32 digest = _getMerkleRootDigest(account, data);
        require(
            !signatureDigestUsed[digest],
            "MerklePublisher: SIGNATURE_USED"
        );
        require(
            _isValid(account, digest, v, r, s),
            "MerklePublisher: SIGNATURE_ERROR"
        );
        signatureDigestUsed[digest] = true;

        platformToMerkleRoot[data.platform] = data.merkleRoot;
        platformToLeavesDigest[data.platform] = data.leavesDigest;
    }

    /// > [[[[[[[[[[[ Publish functions ]]]]]]]]]]]

    function publish(
        address platform,
        bytes32[] calldata proof,
        bytes32 contentDigest
    ) external {
        _verifyMerkleRoot(msg.sender, proof, platform);
        IPlatform(platform).addContentDigest(contentDigest, msg.sender);
    }

    function publishWithSig(
        address owner,
        PublishData calldata data,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 digest = _getPublishDataDigest(owner, data);
        require(
            !signatureDigestUsed[digest],
            "MerklePublisher: SIGNATURE_USED"
        );
        require(
            _isValid(owner, digest, v, r, s),
            "MerklePublisher: SIGNATURE_ERROR"
        );
        _verifyMerkleRoot(owner, data.proof, data.platform);
        signatureDigestUsed[digest] = true;
        IPlatform(data.platform).addContentDigest(
            data.contentDigest,
            msg.sender
        );
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

    function _getPublishDataDigest(address owner, PublishData calldata data)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        PUBLISH_TYPEHASH,
                        owner,
                        data.platform,
                        data.proof,
                        data.contentDigest,
                        data.nonce
                    )
                )
            );
    }

    function _getMerkleRootDigest(address owner, MerkleRootData calldata data)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        SET_MERKLE_ROOT_TYPEHASH,
                        owner,
                        data.platform,
                        data.merkleRoot,
                        data.leavesDigest,
                        data.nonce
                    )
                )
            );
    }

    function _isValid(
        address account,
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool) {
        require(account != address(0), "MerklePublisher: CANNOT_VALIDATE");
        bytes memory signature = abi.encodePacked(r, s, v);
        return SignatureChecker.isValidSignatureNow(account, digest, signature);
    }
}
