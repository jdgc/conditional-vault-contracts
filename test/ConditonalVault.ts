import { ethers, waffle } from "hardhat";
import { Contract, ContractFactory } from "ethers";
import { expect } from "chai";

import * as IERC20 from "../artifacts/@openzeppelin/contracts/token/ERC20/IERC20.sol/IERC20.json";

describe("ConditionalVault", function () {
  let ConditionalVault: ContractFactory;
  let conditionalVault: Contract;

  beforeEach(async function () {
    ConditionalVault = await ethers.getContractFactory("ConditionalVault");
    conditionalVault = await ConditionalVault.deploy();
  });

  describe("whitelistToken", function () {
    it("should add a token address to the whitelist", async function () {
      const DAIAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";

      await conditionalVault.whitelistToken(DAIAddress);
      const firstWhitelistedToken = await conditionalVault.tokenWhitelist(0);

      expect(firstWhitelistedToken).to.eq(DAIAddress);
    });

    it("should fail when called by an address other than the contract owner", async function () {
      const DAIAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
      const [_, userAccount] = await ethers.getSigners();

      await expect(
        conditionalVault.connect(userAccount).whitelistToken(DAIAddress)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("should fail when given an address value that is not a valid ERC20 token", async function () {
      const badAddress = "0x7B175474E89094C44Da98b954EedeAC495271d0G";

      const [_, userAccount] = await ethers.getSigners();

      await expect(
        conditionalVault.connect(userAccount).whitelistToken(badAddress)
      ).to.be.reverted;
    });
  });

  describe("deposit", function () {
    const { deployMockContract } = waffle;
    context("whitelisted token", function () {
      it("updates the user's token balance", async function () {
        const [deployer, userAccount] = await ethers.getSigners();
        const mockERC20 = await deployMockContract(deployer, IERC20.abi);
        const transferAmount = 1000;

        await mockERC20.mock.balanceOf
          .withArgs(conditionalVault.address)
          .returns(1001);
        await conditionalVault.whitelistToken(mockERC20.address);
        await mockERC20.mock.transferFrom
          .withArgs(
            userAccount.address,
            conditionalVault.address,
            transferAmount
          )
          .returns(true);

        await expect(
          conditionalVault
            .connect(userAccount)
            .deposit(mockERC20.address, transferAmount)
        ).to.not.be.reverted;

        expect(
          await conditionalVault.balances(
            userAccount.address,
            mockERC20.address
          )
        ).to.eq(transferAmount);
      });

      it("reverts without updating balance if the ERC20 transfer fails", async function () {
        const [deployer, userAccount] = await ethers.getSigners();
        const mockERC20 = await deployMockContract(deployer, IERC20.abi);
        const transferAmount = 1000;

        await mockERC20.mock.balanceOf
          .withArgs(conditionalVault.address)
          .returns(1001);
        await conditionalVault.whitelistToken(mockERC20.address);
        await mockERC20.mock.transferFrom
          .withArgs(
            userAccount.address,
            conditionalVault.address,
            transferAmount
          )
          .returns(false);

        await expect(
          conditionalVault
            .connect(userAccount)
            .deposit(mockERC20.address, transferAmount)
        ).to.be.reverted;

        expect(
          await conditionalVault.balances(
            userAccount.address,
            mockERC20.address
          )
        ).to.eq(0);
      });
    });
  });
});
