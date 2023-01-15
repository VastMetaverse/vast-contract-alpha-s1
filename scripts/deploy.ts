import { ethers, upgrades } from "hardhat";

async function main() {
  const VastAssets = await ethers.getContractFactory("VastAlphaS1");
  const vastAssets = await upgrades.upgradeProxy(
    "0x3Cc8Fc38aC28fD15A1fC951fD2Dce81C2B70364A",
    VastAssets
  );
  console.log("VastAssets contract deployed to address:", vastAssets.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
