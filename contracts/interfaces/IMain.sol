// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./IDepositFacet.sol";
import "./ISwapFacet.sol";
import "./IBridgeFacet.sol";

interface IMain is IDepositFacet, ISwapFacet, IBridgeFacet {}
