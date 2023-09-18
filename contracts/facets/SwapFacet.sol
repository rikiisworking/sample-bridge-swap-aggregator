// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {LibMain} from "../libraries/LibMain.sol";
import {IUniversalRouter} from "../uniswap/IUniversalRouter.sol";
import {ISmartRouter} from "../pancakeswap/ISmartRouter.sol";

contract SwapFacet {
    using SafeERC20 for IERC20;

    function swap(
        uint16 protocolType,
        address recipient,
        uint256 amountIn,
        uint256 amountOutMin,
        bytes calldata _payload
    ) external {
        require(amountIn > 0, "amountIn should be larger than 0");

        LibMain.MainStorage storage mainStorage = LibMain.mainStorage();
        address router = mainStorage.routers[protocolType];
        require(router != address(0), "unsupported protocolType");

        address[] memory paths = abi.decode(_payload, (address[]));
        require(paths.length > 1, "DFM: Length of paths > 1");

        address tokenOut = paths[paths.length - 1];
        require(paths[0] != address(0) && tokenOut != address(0), "DFM: Native token swap is invalid");
        require(mainStorage.tokenBalances[paths[0]][recipient] >= amountIn, "DFM: Insufficient balance");
        mainStorage.tokenBalances[paths[0]][recipient] -= amountIn;

        IERC20(paths[0]).safeIncreaseAllowance(router, amountIn);
        if (protocolType == LibMain.UNISWAP_V3) {
            _universalRouterSwap(router, paths[0], amountIn, amountOutMin, _payload);
        } else if (protocolType == LibMain.PANCKASWAP_V3) {
            _pancakeswapV3Swap(router, amountIn, amountOutMin, _payload);
        } else {
            revert("unsupported protocol");
        }
    }

    function setRouterAddress(uint16 protocolType, address _routerAddress) external {
        LibMain.MainStorage storage mainStorage = LibMain.mainStorage();
        mainStorage.routers[protocolType] = _routerAddress;
    }

    function _universalRouterSwap(
        address router,
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        bytes calldata payload
    ) internal {
        uint256 deadline = block.timestamp;
        bytes memory command = new bytes(1);
        bytes[] memory inputs = new bytes[](1);

        bytes memory encodedPaths = _extractV3PathFromPayload(payload);
        inputs[0] = abi.encode(address(this), amountIn, amountOutMin, encodedPaths, false);

        IERC20(tokenIn).transfer(router, amountIn);
        try IUniversalRouter(router).execute(command, inputs, deadline) {} catch (bytes memory reason) {
            revert("swap failed");
        }
    }

    function _pancakeswapV3Swap(
        address router,
        uint256 amountIn,
        uint256 amountOutMin,
        bytes calldata payload
    ) internal {
        bytes memory data = _extractV3PathFromPayload(payload);

        ISmartRouter.ExactInputParams memory params = ISmartRouter.ExactInputParams({
            path: data,
            recipient: address(this),
            amountIn: amountIn,
            amountOutMinimum: amountOutMin
        });
        try ISmartRouter(router).exactInput(params) {} catch Error(string memory reason) {
            revert("swap failed");
        } catch (bytes memory reason) {
            revert("swap failed");
        }
    }

    function _extractV3PathFromPayload(bytes calldata payload) internal pure returns (bytes memory data) {
        (address[] memory paths, uint24[] memory poolFees) = abi.decode(payload, (address[], uint24[]));
        uint256 j = 0;
        require(poolFees.length == paths.length - 1, "DFM: Length of poolFees == length of paths - 1");
        for (uint256 i = 0; i < paths.length; i++) {
            data = abi.encodePacked(data, paths[i]);
            if (j <= poolFees.length - 1) {
                data = abi.encodePacked(data, poolFees[j++]);
            }
        }
    }
}
