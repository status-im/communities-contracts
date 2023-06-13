import { ethers } from "hardhat";
import { pn } from "./utils";

async function main() {
  const CommunityERC20 = await ethers.getContractFactory("CommunityERC20");
  const contract = await CommunityERC20.deploy("Test", "TEST", 100);

  const instance = await contract.deployed();
  const tx = instance.deployTransaction;
  const rec = await tx.wait();
  console.log("CommunityERC20 deployed. Gas used:", pn(rec.gasUsed));
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
