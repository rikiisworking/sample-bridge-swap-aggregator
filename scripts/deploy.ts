import { ethers } from "hardhat";

const FacetCutAction = { Add: 0, Replace: 1, Remove: 2 };

async function deployDiamond (verbose: boolean) {
  const accounts = await ethers.getSigners();
  const contractOwner = accounts[0];

  // deploy DiamondCutFacet
  const DiamondCutFacet = await ethers.getContractFactory('DiamondCutFacet')
  const diamondCutFacet = await DiamondCutFacet.deploy()
  await diamondCutFacet.waitForDeployment()
  if(verbose){
    console.log(verbose);
    console.log('DiamondCutFacet deployed:', await diamondCutFacet.getAddress())
  }
  

  // deploy Diamond
  const Diamond = await ethers.getContractFactory('Diamond')
  const diamond = await Diamond.deploy(contractOwner.address, await diamondCutFacet.getAddress())
  await diamond.waitForDeployment()
  if(verbose){
    console.log('Diamond deployed:', await diamond.getAddress())
  }
  

  // deploy DiamondInit
  // DiamondInit provides a function that is called when the diamond is upgraded to initialize state variables
  // Read about how the diamondCut function works here: https://eips.ethereum.org/EIPS/eip-2535#addingreplacingremoving-functions
  const DiamondInit = await ethers.getContractFactory('DiamondInit')
  const diamondInit = await DiamondInit.deploy()
  await diamondInit.waitForDeployment()
  if(verbose){
    console.log('DiamondInit deployed:', await diamondInit.getAddress())
  } 
  

   // deploy facets
   if(verbose){
    console.log('')
    console.log('Deploying facets')
   }

   const FacetNames = [
     'DiamondLoupeFacet',
     'DepositFacet',
     'BridgeFacet',
     'SwapFacet'
   ]
   const cut = []
   for (const FacetName of FacetNames) {
     const Facet = await ethers.getContractFactory(FacetName)
     const facet = await Facet.deploy()
     await facet.waitForDeployment()
     if(verbose){
      console.log(`${FacetName} deployed: ${await facet.getAddress()}`)
     }
     

      const selectors:string[] = [];

     Facet.interface.forEachFunction((func, index)=> {
      selectors.push(func.selector)
     })

      cut.push({
        facetAddress: await facet.getAddress(),
        action: FacetCutAction.Add,
        functionSelectors: selectors,
      });

   }
 
  // upgrade diamond with facets

  if(verbose){
    console.log('')
    console.log('Diamond Cut:', cut)
  }

  const diamondCut = await ethers.getContractAt('IDiamondCut', await diamond.getAddress())
  let tx
  let receipt

  // call to init function

  let functionCall = diamondInit.interface.encodeFunctionData('init')
  tx = await diamondCut.diamondCut(cut, await diamondInit.getAddress(), functionCall)
  if(verbose){
    console.log('Diamond cut tx: ', tx.hash)
  }
  
  receipt = await tx.wait()
  if (!receipt || !receipt.status) {
    throw Error(`Diamond upgrade failed: ${tx.hash}`)
  }
  if(verbose){
    console.log('Completed diamond cut')
  }

  return await diamond.getAddress()
}

async function main() {
  await deployDiamond(true);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

export {deployDiamond}
// exports.deployDiamond = deployDiamond;