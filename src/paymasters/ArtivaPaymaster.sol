// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "@opengsn/contracts/src/BasePaymaster.sol";
import "@opengsn/contracts/src/forwarder/IForwarder.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract ArtivaPaymaster is Ownable, BasePaymaster {
    address public signer;
    mapping(address => bool) allowedTarget;

    /// > [[[[[[[[[[[ Constructor ]]]]]]]]]]]

    constructor(address _signer, address[] memory initalTargets) {
        signer = _signer;
        setManyTargets(initalTargets, true);
    }

    /// > [[[[[[[[[[[ Target functions ]]]]]]]]]]]

    function setTarget(address target, bool allowed) public onlyOwner {
        allowedTarget[target] = allowed;
    }

    function setManyTargets(address[] memory target, bool allowed)
        public
        onlyOwner
    {
        for (uint256 i; i < target.length; i++) {
            allowedTarget[target[i]] = allowed;
        }
    }

    /// > [[[[[[[[[[[ GSN functions ]]]]]]]]]]]

    function _preRelayedCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint256 maxPossibleGas
    )
        internal
        virtual
        override
        returns (bytes memory context, bool revertOnRecipientRevert)
    {
        (signature, maxPossibleGas);

        require(
            allowedTarget[relayRequest.request.to],
            "target not authorized"
        );

        bytes32 requestHash = getRequestHash(relayRequest);
        require(
            signer == ECDSA.recover(requestHash, approvalData),
            "approvalData: wrong signature"
        );

        return ("", false);
    }

    function _postRelayedCall(
        bytes calldata context,
        bool success,
        uint256 gasUseWithoutPost,
        GsnTypes.RelayData calldata relayData
    ) internal virtual override {
        (context, success, gasUseWithoutPost, relayData);
    }

    /// > [[[[[[[[[[[ Signature function ]]]]]]]]]]]

    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function _verifyApprovalData(bytes calldata approvalData)
        internal
        view
        virtual
        override
    {
        require(
            approvalData.length == 65,
            "approvalData: invalid length for signature"
        );
    }

    function getRequestHash(GsnTypes.RelayRequest calldata relayRequest)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    packForwardRequest(relayRequest.request),
                    packRelayData(relayRequest.relayData)
                )
            );
    }

    function packForwardRequest(IForwarder.ForwardRequest calldata req)
        public
        pure
        returns (bytes memory)
    {
        return
            abi.encode(
                req.from,
                req.to,
                req.value,
                req.gas,
                req.nonce,
                req.data
            );
    }

    function packRelayData(GsnTypes.RelayData calldata d)
        public
        pure
        returns (bytes memory)
    {
        return
            abi.encode(
                d.maxFeePerGas,
                d.maxPriorityFeePerGas,
                d.relayWorker,
                d.paymaster,
                d.paymasterData,
                d.clientId
            );
    }

    /// > [[[[[[[[[[[ Meta functions ]]]]]]]]]]]

    function versionPaymaster()
        external
        view
        virtual
        override
        returns (string memory)
    {
        return "3.0.0-beta.0+opengsn.vpm.ipaymaster";
    }
}
