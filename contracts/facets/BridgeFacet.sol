// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {LibMain} from "../libraries/LibMain.sol";
import {IStargateRouter} from "../stargate/IStargateRouter.sol";

struct StargateSwapParams {
    uint256 amount;
    address bridgeToken;
    uint16 dstChainId;
    uint16 srcPoolId;
    uint16 dstPoolId;
    address recipient;
    uint256 extraGas;
    uint256 dustAmount;
    uint256 amountMin;
    address dstContractAddr;
}

contract BridgeFacet {
    using SafeERC20 for IERC20;

    function bridge(
        uint16 protocolType,
        address recipient,
        address _tokenIn,
        uint256 amountIn,
        bytes calldata _payload
    ) external payable {
        require(amountIn > 0, "amountIn should be larger than 0");

        LibMain.MainStorage storage mainStorage = LibMain.mainStorage();
        address router = mainStorage.routers[protocolType];
        require(router != address(0), "unsupported protocolType");
        require(mainStorage.tokenBalances[_tokenIn][recipient] >= amountIn, "DFM: Insufficient balance");

        mainStorage.tokenBalances[_tokenIn][recipient] -= amountIn;
        IERC20(_tokenIn).safeIncreaseAllowance(router, amountIn);
        if (protocolType == LibMain.STARGATE) {
            _stargateBridge(router, recipient, _tokenIn, amountIn, _payload);
        } else {
            revert("unsupported protocol");
        }
    }

    function _stargateBridge(
        address router,
        address recipient,
        address tokenIn,
        uint256 amountIn,
        bytes calldata payload
    ) internal {
        StargateSwapParams memory params = _setStargateParams(recipient, tokenIn, amountIn, payload);
        uint256 fee = getStargateFee(
            params.dstChainId,
            router,
            params.recipient,
            params.dstContractAddr,
            params.extraGas,
            params.dustAmount
        );
        require(params.extraGas > 0, "extragas required");
        require(params.dstContractAddr != address(0), "dst contract required");
        require(msg.value >= fee, "bridge fee required");

        try
            IStargateRouter(router).swap{value: fee}(
                params.dstChainId,
                params.srcPoolId,
                params.dstPoolId,
                payable(msg.sender),
                params.amount,
                params.amountMin,
                IStargateRouter.LzTxObj(params.extraGas, params.dustAmount, abi.encodePacked(params.dstContractAddr)),
                abi.encodePacked(params.dstContractAddr),
                abi.encode(params.recipient)
            )
        {
            IERC20(params.bridgeToken).safeApprove(router, 0);
        } catch {
            revert("bridge failed");
        }
    }

    function _setStargateParams(
        address recipient,
        address tokenIn,
        uint256 amountIn,
        bytes calldata payload
    ) internal pure returns (StargateSwapParams memory params) {
        (
            uint16 dstChainId,
            uint16 srcPoolId,
            uint16 dstPoolId,
            uint256 extraGas,
            uint256 dustAmount,
            uint256 amountMin,
            address dstContractAddr
        ) = abi.decode(payload, (uint16, uint16, uint16, uint256, uint256, uint256, address));
        return
            StargateSwapParams(
                amountIn,
                tokenIn,
                dstChainId,
                srcPoolId,
                dstPoolId,
                recipient,
                extraGas,
                dustAmount,
                amountMin,
                dstContractAddr
            );
    }

    function getStargateFee(
        uint16 dstChainId,
        address router,
        address recipient,
        address dstContractAddr,
        uint256 extraGas,
        uint256 dustAmount
    ) public view returns (uint256 fee) {
        (fee, ) = IStargateRouter(router).quoteLayerZeroFee(
            dstChainId,
            1,
            abi.encodePacked(dstContractAddr),
            abi.encode(recipient),
            IStargateRouter.LzTxObj(extraGas, dustAmount, abi.encodePacked(dstContractAddr))
        );
    }
}
