import { expect } from "chai";
import { ethers } from "hardhat";
import { IMain, IERC20, IWETH, IQuoterV2 } from "../typechain-types"


import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import {deployDiamond} from "../scripts/deploy";

// address follows mainnet settings
const WETH_ADDRESS = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
const USDT_ADDRESS = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
const USDC_ADDRESS = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";

const UNIVERSAL_ROUTER_QUOTER_ADDRESS = "0x61fFE014bA17989E743c5F6cB21bF9697530B21e";

const applySlippage = (amount: bigint, slippage: number) => {

  return amount * BigInt((1-slippage) * 1_000_000) / 1_000_000n;

};

describe("Test", function () {
  let main: IMain;
  let weth: IWETH;
  let usdt: IERC20;
  let usdc: IERC20;
  let quoter: IQuoterV2;

  let user: HardhatEthersSigner;

  const abiCoder = ethers.AbiCoder.defaultAbiCoder()
  const paths = [WETH_ADDRESS, USDT_ADDRESS, USDC_ADDRESS];
  const fees = [3000, 500];
  const quotePath = ethers.solidityPacked(
    ["address", "uint24", "address", "uint24", "address"],
    [paths[0], fees[0], paths[1], fees[1], paths[2]],
  );

  const payloadV3 = abiCoder.encode(["address[]", "uint24[]"], [paths, fees]);
  const slippage = 0.05;
  
  
  before(async () => {
    [user] = await ethers.getSigners();
    
    weth = await ethers.getContractAt("IWETH", WETH_ADDRESS);
    usdt = await ethers.getContractAt("IERC20", USDT_ADDRESS);
    usdc = await ethers.getContractAt("IERC20", USDC_ADDRESS);

    quoter = await ethers.getContractAt("IQuoterV2", UNIVERSAL_ROUTER_QUOTER_ADDRESS);
    await weth.connect(user).deposit({ value: ethers.parseEther("100") });

  
  })

  beforeEach(async () => {
    const address = await deployDiamond(false);
    main = await ethers.getContractAt("IMain", address);
    await main.setRouterAddress(0, "0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD");
    await main.setRouterAddress(10, "0x8731d54E9D02c286767d56ac03e8037C07e01e98");
  })

  it("deposit() should work as expected", async () => {
    const depositAmount = ethers.parseEther("0.1");
    await weth.connect(user).approve(main, depositAmount);
    await main.deposit(weth, depositAmount);
    await main.balanceOf(weth, user).then((result: BigInt) => {
      expect(result).to.equal(depositAmount);
    })
  })

  it("withdraw() should work as expected", async () => {
    const depositAmount = ethers.parseEther("0.1");
    await weth.connect(user).approve(main, depositAmount);
    await main.deposit(weth, depositAmount);
    await main.withdraw(weth, user);
    await main.balanceOf(weth, user).then((result: BigInt) => {
      expect(result).to.equal(BigInt(0));
    })
  })

  it("setRouterAddress() should work as expected", async () => {
    const multichainRouterAddr = "0x1633D66Ca91cE4D81F63Ea047B7B19Beb92dF7f3";
    await main.setRouterAddress(11, multichainRouterAddr);
    await main.getRouterAddress(11).then((result: string) => {
      expect(result).to.equal(multichainRouterAddr)
    })
  })

  it("swap() should work as expected", async () => {
    const swapAmount = ethers.parseEther("0.1");
    await weth.connect(user).approve(main, swapAmount);
    await main.deposit(weth, swapAmount);
    
    const quoteResult = (await quoter.quoteExactInput.staticCall(quotePath, swapAmount)) as {
      amountOut: bigint;
    };
    const amountOutMin = applySlippage(quoteResult.amountOut, slippage);

    await main.connect(user).swap(0, user, swapAmount, amountOutMin, payloadV3);

    await main.balanceOf(USDC_ADDRESS, user).then((result: BigInt)=> {
      console.log("swappedAmount:"+result);
      expect(result).gt(BigInt(0));
    })

  })

  it("test", async () => {
    console.log("testing hook")
  })
})