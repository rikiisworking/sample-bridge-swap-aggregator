// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface ISwapFacet {
    function swap(
        uint16 protocolType,
        address recipient,
        uint256 amountIn,
        uint256 amountOutMin,
        bytes calldata _payload
    ) external;

    function setRouterAddress(uint16 protocolType, address _routerAddress) external;

    function getRouterAddress(uint16 protocolType) external view returns (address);
}
