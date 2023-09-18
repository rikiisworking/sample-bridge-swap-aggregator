// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.18;

interface IStargatePool {
    struct ChainPath {
        bool ready; // indicate if the counter chainPath has been created.
        uint16 dstChainId;
        uint256 dstPoolId;
        uint256 weight;
        uint256 balance;
        uint256 lkb;
        uint256 credits;
        uint256 idealBalance;
    }

    function feeLibrary() external view returns (address);

    function token() external view returns (address);

    function decimals() external view returns (uint256);

    function localDecimals() external view returns (uint256);

    function convertRate() external view returns (uint256);

    function getChainPath(uint16 _dstChainId, uint256 _dstPoolId) external view returns (ChainPath memory);
}
