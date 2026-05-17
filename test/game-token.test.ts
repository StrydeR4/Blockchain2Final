import { expect } from "chai";
import { ethers } from "hardhat";

describe("GameToken", function () {
  it("supports delegation and voting power", async function () {
    const [owner, voter] = await ethers.getSigners();
    const GameToken = await ethers.getContractFactory("GameToken");
    const token = await GameToken.deploy(owner.address);

    await token.transfer(voter.address, ethers.parseEther("100"));
    await token.connect(voter).delegate(voter.address);
    expect(await token.getVotes(voter.address)).to.equal(ethers.parseEther("100"));
  });
});
