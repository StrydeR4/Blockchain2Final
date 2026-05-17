import { expect } from "chai";
import { ethers } from "hardhat";

describe("ResourceAMM", function () {
  async function fixture() {
    const [owner, trader] = await ethers.getSigners();
    const Token = await ethers.getContractFactory("ResourceToken");
    const wood = await Token.deploy(owner.address, "Wood", "WOOD");
    const crystal = await Token.deploy(owner.address, "Crystal", "CRYSTAL");
    const Feed = await ethers.getContractFactory("MockV3Aggregator");
    const feed = await Feed.deploy(8, 100_00000000);
    const Oracle = await ethers.getContractFactory("ChainlinkPriceOracle");
    const oracle = await Oracle.deploy(await feed.getAddress(), 3600);
    const AMM = await ethers.getContractFactory("ResourceAMM");
    const amm = await AMM.deploy(
      owner.address,
      await wood.getAddress(),
      await crystal.getAddress(),
      await oracle.getAddress()
    );

    for (const token of [wood, crystal]) {
      await token.mint(owner.address, ethers.parseEther("10000"));
      await token.mint(trader.address, ethers.parseEther("1000"));
      await token.connect(owner).approve(await amm.getAddress(), ethers.MaxUint256);
      await token.connect(trader).approve(await amm.getAddress(), ethers.MaxUint256);
    }
    return { owner, trader, wood, crystal, feed, amm };
  }

  it("adds liquidity and mints LP shares", async function () {
    const { amm } = await fixture();
    await expect(amm.addLiquidity(ethers.parseEther("100"), ethers.parseEther("100"), 1)).to.emit(
      amm,
      "LiquidityAdded"
    );
    expect(await amm.totalSupply()).to.be.gt(0);
  });

  it("swaps with slippage protection", async function () {
    const { trader, wood, crystal, amm } = await fixture();
    await amm.addLiquidity(ethers.parseEther("100"), ethers.parseEther("100"), 1);
    await expect(
      amm
        .connect(trader)
        .swap(await wood.getAddress(), ethers.parseEther("10"), ethers.parseEther("8"))
    ).to.emit(amm, "Swapped");
    expect(await crystal.balanceOf(trader.address)).to.be.gt(ethers.parseEther("900"));
  });

  it("reverts when oracle price is stale", async function () {
    const { trader, wood, feed, amm } = await fixture();
    await amm.addLiquidity(ethers.parseEther("100"), ethers.parseEther("100"), 1);
    await feed.setUpdatedAt(1);
    await expect(
      amm.connect(trader).swap(await wood.getAddress(), ethers.parseEther("10"), 1)
    ).to.be.revertedWithCustomError(
      await ethers.getContractAt("ChainlinkPriceOracle", await amm.oracle()),
      "StalePrice"
    );
  });
});
