import { ethers } from "hardhat"
import { Contract, ContractFactory } from "ethers";
import { expect } from "chai";

describe("Test", function() {
  let Test: ContractFactory;
  let test: Contract;

  beforeEach(async function() {
    Test = await ethers.getContractFactory("Test")
    test = await Test.deploy()
  });

  describe("helloWorld",  function() {
    it("should return hello world", async function() {
      expect(await test.helloWorld()).to.equal("hello world");
    })
  })
})
