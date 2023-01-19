import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { Currency } from "../typechain-types/contracts/mocks/Currency";
import { BuyableSoulbound } from "../typechain-types/contracts/BuyableSoulbound";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import {
  BN,
  constants,
  expectEvent,
  expectRevert,
} from "@openzeppelin/test-helpers";

const tokenUtils = {
  fromUnit: (amount: number) => new BN(amount).mul(new BN(10).pow(new BN(18)))
};

describe("BuyableSoulbound", function () {
  describe("deployment", function () {
    let owner: SignerWithAddress;
    let accounts: SignerWithAddress[];
    let beneficiary: SignerWithAddress;
    let currency: Currency;
    let token: BuyableSoulbound;

    beforeEach(async () => {
      [owner, beneficiary, ...accounts] = await ethers.getSigners();

      const Currency = await ethers.getContractFactory("Currency");
      currency = await Currency.deploy();

      const BuyableSoulbound = await ethers.getContractFactory("BuyableSoulbound");
      token = await BuyableSoulbound.deploy(
        "Test Soulbound",
        "SOUL",
        "http://test.local",
        beneficiary.address,
        currency.address,
        tokenUtils.fromUnit(10).toString()
      );
    });

    it("deploys with right attributes", async () => {
      expect(await token.name()).to.equal("Test Soulbound");
      expect(await token.symbol()).to.equal("SOUL");
      expect(await token.beneficiary()).to.equal(beneficiary.address);
      expect(await token.paymentToken()).to.equal(currency.address);
      expect(await token.tokenPrice()).to.equal("10000000000000000000");
    });

    const transferCurrency = async (account: SignerWithAddress, amount: any) => {
      await currency.mint(account.address, amount.toString());
    };

    const approveCurrency = async (owner: SignerWithAddress, spender: string, amount: any) => {
      await currency.connect(owner).approve(spender, amount.toString());
    };

    it("allows users to mint paying with Currency", async () => {
      const a = accounts[0];
      await transferCurrency(a, tokenUtils.fromUnit(10));
      await approveCurrency(a, token.address, tokenUtils.fromUnit(10));
      await token.connect(a).mint();
    });

    it("fails with not enough allowance", async () => {
      const a = accounts[0];
      await transferCurrency(a, tokenUtils.fromUnit(10));
      await approveCurrency(a, token.address, tokenUtils.fromUnit(5));
      await expect(
        token.connect(a).mint()
      ).to.be.revertedWith("ERC20: insufficient allowance");
    });

    it("fails with not enough balance", async () => {
      const a = accounts[0];
      await transferCurrency(a, tokenUtils.fromUnit(5));
      await approveCurrency(a, token.address, tokenUtils.fromUnit(10));
      await expect(
        token.connect(a).mint()
      ).to.be.revertedWith("ERC20: transfer amount exceeds balance");
    });
  });
});
