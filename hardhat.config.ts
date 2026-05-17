import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";
import "@nomicfoundation/hardhat-verify";
import "hardhat-gas-reporter";
import { HardhatUserConfig } from "hardhat/config";

const PRIVATE_KEY = process.env.PRIVATE_KEY ?? "0x0000000000000000000000000000000000000000000000000000000000000001";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: { enabled: true, runs: 200 },
      evmVersion: "cancun"
    }
  },
  networks: {
    hardhat: { chainId: 31337 },
    arbitrumSepolia: {
      url: process.env.ARBITRUM_SEPOLIA_RPC_URL ?? "",
      accounts: [PRIVATE_KEY]
    },
    optimismSepolia: {
      url: process.env.OPTIMISM_SEPOLIA_RPC_URL ?? "",
      accounts: [PRIVATE_KEY]
    },
    baseSepolia: {
      url: process.env.BASE_SEPOLIA_RPC_URL ?? "",
      accounts: [PRIVATE_KEY]
    }
  },
  etherscan: {
    apiKey: {
      arbitrumSepolia: process.env.ARBISCAN_API_KEY ?? "",
      optimisticSepolia: process.env.OPTIMISM_ETHERSCAN_API_KEY ?? "",
      baseSepolia: process.env.BASESCAN_API_KEY ?? ""
    }
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS === "true",
    currency: "USD"
  }
};

export default config;

