import { ethers } from "hardhat";
import { pn } from "./utils";

async function main() {
  const CollectibleV1 = await ethers.getContractFactory("CollectibleV1");
  const contract = await CollectibleV1.deploy(
    "Test",
    "TEST",
    100,
    true,
    true,
    "http://local.dev"
  );

  const instance = await contract.deployed();
  const tx = instance.deployTransaction;
  const rec = await tx.wait();
  console.log("CollectibleV1 deployed. Gas used:", pn(rec.gasUsed));
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
