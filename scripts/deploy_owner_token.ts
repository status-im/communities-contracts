import { ethers } from "hardhat";
import { pn } from "./utils";

async function main() {
  const CollectibleV1 = await ethers.getContractFactory("OwnerToken");
  const contract = await CollectibleV1.deploy(
    "Test",
    "TEST",
    "http://local.dev",
    "Test 2",
    "TEST 2",
    "http://local2.dev",
    "0x12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678"
  );

  const instance = await contract.deployed();
  const tx = instance.deployTransaction;
  const rec = await tx.wait();
  console.log(
    `OwnerToken deployed at ${instance.address}. Gas used: ${pn(rec.gasUsed)}`
  );
  console.log("Master token deployed at", rec.events[0].args.masterToken);
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
