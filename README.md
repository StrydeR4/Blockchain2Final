## Blockchain Technologies 2 — Final Project

The protocol combines:
- ERC20 governance token
- ERC1155 in-game assets
- AMM marketplace
- ERC4626 staking vault
- DAO governance
- Chainlink oracle integrations
- Layer 2 deployment
- Full frontend dApp
- Security-focused architecture

---

# Project Scenario

This project follows:

## Option B — GameFi Economy

The platform implements:
- ERC1155 in-game item economy
- Crafting system
- Marketplace AMM for fungible resources
- NFT staking and vault mechanics
- DAO-governed balancing
- Chainlink integrations
- L2 deployment

---

# Tech Stack

## Smart Contracts
- Solidity ^0.8.x
- Hardhat
- OpenZeppelin Contracts

## Frontend
- React
- Ethers.js
- MetaMask

## Infrastructure
- Alchemy RPC
- Base Sepolia
- GitHub Actions

## Indexing
- The Graph

---

# Core Contracts

## LootToken.sol

Governance token implementing:
- ERC20
- ERC20Votes
- ERC20Permit

Features:
- Governance voting
- Delegation
- Proposal participation

---

## GameItems.sol

ERC1155 multi-token item system.

Example items:
- Wood
- Iron
- Gold
- Sword
- Epic Sword

---

## Crafting.sol

Crafting engine allowing players to:
- Burn resources
- Mint crafted items
- Upgrade equipment

---

## LootAMM.sol

Custom AMM marketplace implementing:
- x * y = k invariant
- Liquidity pools
- LP tokens
- Slippage protection
- 0.3% trading fee

---

## GoldVault.sol

ERC4626 staking vault.

Players can:
- Deposit Gold
- Earn protocol yield
- Withdraw vault shares

---

## Governor.sol

DAO governance module including:
- OpenZeppelin Governor
- TimelockController
- Proposal voting
- Execution queue

---

# Governance Parameters

| Parameter | Value |
|---|---|
| Voting Delay | 1 day |
| Voting Period | 1 week |
| Quorum | 4% |
| Proposal Threshold | 1% |
| Timelock Delay | 2 days |

These values follow the official project requirements. :contentReference[oaicite:1]{index=1}

---

# Security Features

The protocol follows:
- Checks-Effects-Interactions pattern
- Reentrancy protection
- AccessControl / Ownable authorization
- SafeERC20 token interactions
- Oracle staleness checks
- Timelock governance protection

The protocol does NOT use:
- tx.origin authorization
- block.timestamp randomness
- deprecated transfer/send ETH patterns

Security implementation follows the project specification. :contentReference[oaicite:2]{index=2}

---

# Testing

The project includes:
- Unit tests
- Fuzz tests
- Invariant tests
- Fork tests

Target:
- 90%+ line coverage

Testing requirements follow the official specification. :contentReference[oaicite:3]{index=3}

---

# Frontend Features

The frontend supports:
- MetaMask wallet connection
- Wallet balance display
- Governance voting
- AMM swaps
- Crafting actions
- Proposal tracking
- Network detection
- User-friendly error handling

Frontend functionality follows the project requirements. :contentReference[oaicite:4]{index=4}

---

# Deployment

Target deployment:
- Base Sepolia

Optional deployment:
- Arbitrum Sepolia
- Optimism Sepolia

Contracts are deployed and verified through automated deployment scripts.

---

# Installation

## Clone Repository

```bash
git clone <repository_url>
cd lootforge-dao
```

---

## Install Dependencies

```bash
npm install
```

---

## Compile Contracts

```bash
npx hardhat compile
```

---

## Run Tests

```bash
npx hardhat test
```

---

## Start Local Network

```bash
npx hardhat node
```

---

## Deploy Contracts Locally

```bash
npx hardhat run scripts/deploy.js --network localhost
```

---

# Environment Variables

Create a `.env` file in the project root:

```env
PRIVATE_KEY=
BASE_SEPOLIA_RPC_URL=
ETHERSCAN_API_KEY=
```

---

# CI/CD

The project uses GitHub Actions for continuous integration and automated validation.

The CI pipeline includes:
- Smart contract compilation
- Automated testing
- Coverage generation
- Linting and formatting checks
- Security analysis

Main tools:
- Hardhat
- Mocha / Chai
- Solidity Coverage
- Solhint
- Prettier

The pipeline runs automatically on:
- every push
- every pull request

This helps maintain code quality, security, and repository stability during development.

---

# Design Patterns Used

The protocol implements several blockchain engineering patterns.

## Factory Pattern
Used for scalable deployment of protocol components.

## UUPS Upgradeability
Allows upgradeable smart contracts while preserving storage.

## Access Control
Administrative actions are protected using role-based permissions.

## Checks-Effects-Interactions
Used to reduce reentrancy risks.

## Reentrancy Guard
Protects sensitive functions involving external calls.

## Timelock Governance
Governance proposals are executed through a delayed TimelockController.

## Oracle Adapter Pattern
Chainlink integrations are abstracted through interfaces.

## State Machine Logic
Governance proposals and crafting flows follow predefined lifecycle states.

These patterns improve maintainability, modularity, scalability, and protocol security. :contentReference[oaicite:5]{index=5}

---

# Future Improvements

Possible future upgrades:
- Cross-chain asset support
- NFT rental mechanics
- Advanced crafting recipes
- Dynamic loot generation
- Seasonal events and tournaments
- Additional DAO-controlled balancing systems
- Expanded staking mechanics
- Multi-token liquidity pools
- Mobile-friendly frontend optimization
- Additional Chainlink integrations

---

# License

MIT
