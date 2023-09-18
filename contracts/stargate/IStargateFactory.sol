// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.18;

interface IStargateFactory {
    function getPool(uint256 poolId) external view returns (address poolAddress);
}
