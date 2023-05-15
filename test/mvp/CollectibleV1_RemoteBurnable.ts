import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { CollectibleV1 } from "../../typechain-types/contracts/mvp/CollectibleV1";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
// import BigNumber from "bignumber.js";
import {
  constants,
  expectEvent,
  expectRevert,
} from "@openzeppelin/test-helpers";

const BN = (n: string | number) => ethers.BigNumber.from(n.toString());

const tokenUtils = {
  fromUnit: (amount: number) => BN(amount).mul(BN(10).pow(BN(18))),
};

describe("CollectibleV1", function () {
  describe("deployment", function () {
    let owner: SignerWithAddress;
    let accounts: SignerWithAddress[];
    let token: CollectibleV1;
    let maxSupply: ReturnType<typeof BN>;

    before(async () => {
      [owner, ...accounts] = await ethers.getSigners();
      const CollectibleV1 = await ethers.getContractFactory("CollectibleV1");

      maxSupply = BN(2).pow(BN(256)).sub(BN(1));

      token = await CollectibleV1.deploy(
        "Test Token",
        "TEST",
        maxSupply.toString(),
        true,
        true,
        "http://test.local"
      );
    });

    it("deploys with right attributes", async () => {
      expect(await token.name()).to.equal("Test Token");
      expect(await token.symbol()).to.equal("TEST");
      expect(await token.maxSupply()).to.equal(maxSupply);
      expect(await token.remoteBurnable()).to.equal(true);
      expect(await token.transferable()).to.equal(true);
      expect(await token.baseTokenURI()).to.equal("http://test.local");
    });

    it("normal user cannot mint", async () => {
      const a = accounts[0];
      await expect(token.connect(a).mintTo([a.address])).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
    });

    it("owner can mint", async () => {
      const addresses = accounts.map((a) => a.address);
      for (let i = 0; i < addresses.length; i++) {
        expect(await token.balanceOf(addresses[i])).to.equal("0");
      }

      await token.connect(owner).mintTo(addresses);

      for (let i = 0; i < addresses.length; i++) {
        expect(await token.balanceOf(addresses[i])).to.equal("1");
      }
    });

    it("normal user cannot burn", async () => {
      const a = accounts[0];
      await expect(token.connect(a).remoteBurn([0])).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
    });

    it("owner can remote burn", async () => {
      const totalSupplyBefore = await token.totalSupply();
      await token.connect(owner).remoteBurn([0]);
      const totalSupplyAfter = await token.totalSupply();
      expect(totalSupplyAfter.toString()).to.equal(
        totalSupplyBefore.sub(BN(1))
      );
    });

    // it("fails with not enough allowance", async () => {
    //   const a = accounts[0];
    //   await transferCurrency(a, tokenUtils.fromUnit(10));
    //   await approveCurrency(a, token.address, tokenUtils.fromUnit(5));
    //   await expect(
    //     token.connect(a).mint()
    //   ).to.be.revertedWith("ERC20: insufficient allowance");
    // });

    // it("fails with not enough balance", async () => {
    //   const a = accounts[0];
    //   await transferCurrency(a, tokenUtils.fromUnit(5));
    //   await approveCurrency(a, token.address, tokenUtils.fromUnit(10));
    //   await expect(
    //     token.connect(a).mint()
    //   ).to.be.revertedWith("ERC20: transfer amount exceeds balance");
    // });
  });
});
