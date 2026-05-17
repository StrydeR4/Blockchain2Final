import { ethers } from "hardhat";

async function main() {
  const timelockAddress = process.env.TIMELOCK_ADDRESS;
  const governorAddress = process.env.GOVERNOR_ADDRESS;
  if (!timelockAddress || !governorAddress) {
    throw new Error("Set TIMELOCK_ADDRESS and GOVERNOR_ADDRESS");
  }

  const timelock = await ethers.getContractAt("TimelockController", timelockAddress);
  const governor = await ethers.getContractAt("GameGovernor", governorAddress);

  const minDelay = await timelock.getMinDelay();
  const votingDelay = await governor.votingDelay();
  const votingPeriod = await governor.votingPeriod();
  const quorumDenominator = await governor.quorumDenominator();

  console.table({
    timelock: timelockAddress,
    governor: governorAddress,
    minDelay: minDelay.toString(),
    votingDelay: votingDelay.toString(),
    votingPeriod: votingPeriod.toString(),
    quorumDenominator: quorumDenominator.toString()
  });

  if (minDelay !== 172800n) throw new Error("Timelock delay mismatch");
  if (votingDelay !== 86400n) throw new Error("Voting delay mismatch");
  if (votingPeriod !== 604800n) throw new Error("Voting period mismatch");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
