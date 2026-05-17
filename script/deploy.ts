import { ethers, upgrades } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  const chainId = (await ethers.provider.getNetwork()).chainId;
  console.log(`Deploying GameFi Economy with ${deployer.address} on chain ${chainId}`);

  const GameToken = await ethers.getContractFactory("GameToken");
  const govToken = await GameToken.deploy(deployer.address);
  await govToken.waitForDeployment();

  const minDelay = 2 * 24 * 60 * 60;
  const Timelock = await ethers.getContractFactory("TimelockController");
  const timelock = await Timelock.deploy(minDelay, [], [], deployer.address);
  await timelock.waitForDeployment();

  const Governor = await ethers.getContractFactory("GameGovernor");
  const governor = await Governor.deploy(await govToken.getAddress(), await timelock.getAddress());
  await governor.waitForDeployment();

  const proposerRole = await timelock.PROPOSER_ROLE();
  const executorRole = await timelock.EXECUTOR_ROLE();
  const adminRole = await timelock.DEFAULT_ADMIN_ROLE();
  await timelock.grantRole(proposerRole, await governor.getAddress());
  await timelock.grantRole(executorRole, ethers.ZeroAddress);
  await timelock.revokeRole(adminRole, deployer.address);

  const ResourceToken = await ethers.getContractFactory("ResourceToken");
  const wood = await ResourceToken.deploy(await timelock.getAddress(), "Wood", "WOOD");
  await wood.waitForDeployment();
  const crystal = await ResourceToken.deploy(await timelock.getAddress(), "Crystal", "CRYSTAL");
  await crystal.waitForDeployment();

  const Items = await ethers.getContractFactory("GameItems");
  const items = await Items.deploy(await timelock.getAddress(), "ipfs://gamefi-economy/{id}.json");
  await items.waitForDeployment();

  const MockFeed = await ethers.getContractFactory("MockV3Aggregator");
  const mockFeed = await MockFeed.deploy(8, 100_00000000);
  await mockFeed.waitForDeployment();

  const Oracle = await ethers.getContractFactory("ChainlinkPriceOracle");
  const oracle = await Oracle.deploy(await mockFeed.getAddress(), 3600);
  await oracle.waitForDeployment();

  const AMM = await ethers.getContractFactory("ResourceAMM");
  const amm = await AMM.deploy(
    await timelock.getAddress(),
    await wood.getAddress(),
    await crystal.getAddress(),
    await oracle.getAddress()
  );
  await amm.waitForDeployment();

  const Config = await ethers.getContractFactory("GameConfigUpgradeable");
  const config = await upgrades.deployProxy(Config, [await timelock.getAddress()], {
    kind: "uups"
  });
  await config.waitForDeployment();

  const RentalVault = await ethers.getContractFactory("RentalVault");
  const rentalVault = await RentalVault.deploy(
    await timelock.getAddress(),
    await wood.getAddress(),
    await items.getAddress()
  );
  await rentalVault.waitForDeployment();

  const Crafting = await ethers.getContractFactory("CraftingSystem");
  const crafting = await Crafting.deploy(await timelock.getAddress(), await items.getAddress());
  await crafting.waitForDeployment();

  const Factory = await ethers.getContractFactory("GameFactory");
  const factory = await Factory.deploy(await timelock.getAddress());
  await factory.waitForDeployment();

  console.table({
    govToken: await govToken.getAddress(),
    timelock: await timelock.getAddress(),
    governor: await governor.getAddress(),
    wood: await wood.getAddress(),
    crystal: await crystal.getAddress(),
    items: await items.getAddress(),
    oracle: await oracle.getAddress(),
    amm: await amm.getAddress(),
    config: await config.getAddress(),
    rentalVault: await rentalVault.getAddress(),
    crafting: await crafting.getAddress(),
    factory: await factory.getAddress()
  });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
