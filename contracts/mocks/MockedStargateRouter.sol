// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MockedStargateRouter {
    struct LzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        LzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable {}

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        LzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256) {
        return (25000000000000000, 25000000000000000);
    }
}
