import { ethers, waffle } from "hardhat";
import { Contract, ContractFactory } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";

import * as IERC20 from "../artifacts/@openzeppelin/contracts/token/ERC20/IERC20.sol/IERC20.json";

describe("ConditionalVault", async function () {
  const { deployMockContract } = waffle;
  let ConditionalVault: ContractFactory;
  let conditionalVault: Contract;
  let deployer: SignerWithAddress;
  let userAccount: SignerWithAddress;
  let mockERC20;

  beforeEach(async function () {
    ConditionalVault = await ethers.getContractFactory("ConditionalVault");
    conditionalVault = await ConditionalVault.deploy();
    [deployer, userAccount] = await ethers.getSigners();
  });

  describe("conditionSatisfied", function() {
    const depositAmount = 1000;
    let ETHUSD_address = "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419";
    let conditionValue = 400000000;


    beforeEach(async function () {
      const mockERC20 = await deployMockContract(deployer, IERC20.abi);

      await mockERC20.mock.balanceOf
        .withArgs(conditionalVault.address)
        .returns(1001);
      await conditionalVault.whitelistToken(mockERC20.address);
      await mockERC20.mock.transferFrom
        .withArgs(
          userAccount.address,
          conditionalVault.address,
          depositAmount
        )
        .returns(true);
      await
      conditionalVault
        .connect(userAccount)
        .createConditionLockedDeposit(
          mockERC20.address,
          ETHUSD_address,
          conditionValue,
          1,
          depositAmount
        )
    });


    it("returns true if the deposit condition is met", async function() {
      expect(await conditionalVault.conditionSatisfied(userAccount.address, 0)).to.eq(false);  
    });  
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

  describe("createConditionLockedDeposit", async function () {
      const { deployMockContract } = waffle;
      const ETHUSD_address = "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419";
      const [deployer, userAccount] = await ethers.getSigners();
      const mockERC20 = await deployMockContract(deployer, IERC20.abi);
      const depositAmount = 1000;
      const conditionValue = 400000000;

    context("whitelisted token", async function () {
      context("ERC20 token transfer succeeds", async function () {
        before(async () => {
          await mockERC20.mock.balanceOf
            .withArgs(conditionalVault.address)
            .returns(1001);
          await conditionalVault.whitelistToken(mockERC20.address);
          await mockERC20.mock.transferFrom
            .withArgs(
              userAccount.address,
              conditionalVault.address,
              depositAmount
            )
            .returns(true);
        });

        it("does not revert", async function () {
          await expect(
            conditionalVault
              .connect(userAccount)
              .createConditionLockedDeposit(
                mockERC20.address,
                ETHUSD_address,
                conditionValue,
                0,
                depositAmount
              )
          ).to.not.be.reverted;
        });

        it("creates a new ConditionLockedDeposit", async function () {
          const userDeposit = await conditionalVault.conditionLockedDeposits(
            userAccount.address,
            0
          );
          expect(userDeposit).to.not.be.null;
          expect(userDeposit.amount).to.eq(depositAmount);
        });
      });

        context("ERC20 Token Transfer fails", async function() {
          before(async () => {
            await mockERC20.mock.transferFrom
              .withArgs(
                userAccount.address,
                conditionalVault.address,
                depositAmount
              )
              .returns(false);
          });

          it("reverts", async function() {
            await expect(
              conditionalVault
              .connect(userAccount)
              .createConditionLockedDeposit(
                mockERC20.address,
                ETHUSD_address,
                conditionValue,
                0,
                depositAmount
              )
            ).to.be.reverted;
          })
        })
    });
  });
});
