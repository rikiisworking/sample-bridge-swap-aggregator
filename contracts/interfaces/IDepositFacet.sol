// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IDepositFacet {
    function deposit(address tokenIn, uint256 amountIn) external;

    function withdraw(address tokenOut, address recipient) external;

    function balanceOf(address tokenIn, address user) external view returns (uint256);
}
