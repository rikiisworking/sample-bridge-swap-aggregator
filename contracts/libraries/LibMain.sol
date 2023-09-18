// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library LibMain {
    bytes32 public constant MAIN_STORAGE_POSITION = keccak256("diamond.standard.diamond.main");

    struct MainStorage {
        mapping(address tokenAddress => mapping(address userAddress => uint256 tokenBalance)) tokenBalances;
        mapping(uint16 protocolType => address routerAddress) routers;
    }

    uint16 public constant UNISWAP_V3 = 0;
    uint16 public constant PANCKASWAP_V3 = 1;
    uint16 public constant STARGATE = 10;

    function mainStorage() internal pure returns (MainStorage storage ds) {
        bytes32 position = MAIN_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}
