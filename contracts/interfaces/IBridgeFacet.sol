// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IBridgeFacet {
    function bridge(
        uint16 protocolType,
        address recipient,
        address _tokenIn,
        uint256 amountIn,
        bytes calldata _payload
    ) external payable;

    function getStargateFee(
        uint16 dstChainId,
        address router,
        address recipient,
        address dstContractAddr,
        uint256 extraGas,
        uint256 dustAmount
    ) external view returns (uint256 fee);
}
