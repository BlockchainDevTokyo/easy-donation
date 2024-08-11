import { expect } from "chai";
import { ethers } from "hardhat";
import { SeedlessWallet } from "../typechain-types";

describe("SeedlessWallet", function () {
  // We define a fixture to reuse the same setup in every test.

  let SeedlessWallet: SeedlessWallet;
  before(async () => {
    const [owner] = await ethers.getSigners();
    const SeedlessWalletFactory = await ethers.getContractFactory("SeedlessWallet");
    SeedlessWallet = (await SeedlessWalletFactory.deploy(owner.address)) as SeedlessWallet;
    await SeedlessWallet.waitForDeployment();
  });

  describe("Deployment", function () {
    it("Should have the right message on deploy", async function () {
      expect(await SeedlessWallet.greeting()).to.equal("Building Unstoppable Apps!!!");
    });

    it("Should allow setting a new message", async function () {
      const newGreeting = "Learn Scaffold-ETH 2! :)";

      await SeedlessWallet.setGreeting(newGreeting);
      expect(await SeedlessWallet.greeting()).to.equal(newGreeting);
    });
  });
});
