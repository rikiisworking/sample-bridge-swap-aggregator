// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IDepositFacet} from "../interfaces/IDepositFacet.sol";
import {LibMain} from "../libraries/LibMain.sol";

contract DepositFacet is IDepositFacet {
    using SafeERC20 for IERC20;

    function deposit(address tokenIn, uint256 amountIn) external {
        require(amountIn > 0, "amountIn should be larger than 0");
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        LibMain.MainStorage storage mainStorage = LibMain.mainStorage();
        mainStorage.tokenBalances[tokenIn][msg.sender] += amountIn;
    }

    function withdraw(address tokenOut, address recipient) external {
        LibMain.MainStorage storage mainStorage = LibMain.mainStorage();
        uint256 tokenBalance = mainStorage.tokenBalances[tokenOut][recipient];
        require(tokenBalance > 0, "nothing to withdraw");
        IERC20(tokenOut).safeTransfer(recipient, tokenBalance);
        mainStorage.tokenBalances[tokenOut][recipient] = 0;
    }

    function balanceOf(address token, address user) external view returns (uint256) {
        LibMain.MainStorage storage mainStorage = LibMain.mainStorage();
        return mainStorage.tokenBalances[token][user];
    }
}
