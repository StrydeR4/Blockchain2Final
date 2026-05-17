# Architecture Document Draft

## System Context

```mermaid
C4Context
title GameFi Economy Context
Person(player, "Player", "Crafts items, swaps resources, rents NFTs, opens loot")
Person(dao, "DAO Voter", "Delegates, proposes, votes, executes parameter changes")
System(protocol, "GameFi Economy Protocol", "ERC-1155 items, AMM, rental vault, VRF loot, governance")
System_Ext(chainlink, "Chainlink", "Price feeds and VRF")
System_Ext(graph, "The Graph", "Indexes protocol events")
System_Ext(l2, "Base Sepolia", "Target L2 deployment")
Rel(player, protocol, "Uses")
Rel(dao, protocol, "Governs")
Rel(protocol, chainlink, "Reads price / requests randomness")
Rel(graph, protocol, "Indexes events")
Rel(protocol, l2, "Runs on")
```

## Component Model

```mermaid
flowchart LR
  "React dApp" --> "GameGovernor"
  "React dApp" --> "ResourceAMM"
  "React dApp" --> "RentalVault"
  "React dApp" --> "The Graph Subgraph"
  "GameGovernor" --> "TimelockController"
  "TimelockController" --> "GameConfigUpgradeable UUPS Proxy"
  "TimelockController" --> "LootDrop"
  "TimelockController" --> "CraftingSystem"
  "ResourceAMM" --> "ResourceToken WOOD"
  "ResourceAMM" --> "ResourceToken CRYSTAL"
  "ResourceAMM" --> "ChainlinkPriceOracle"
  "LootDrop" --> "Chainlink VRF"
  "CraftingSystem" --> "GameItems ERC1155"
  "RentalVault" --> "GameItems ERC1155"
```

## Critical Flows

### Swap

```mermaid
sequenceDiagram
  actor Player
  participant UI as React dApp
  participant AMM as ResourceAMM
  participant Oracle as ChainlinkPriceOracle
  participant Token as ResourceToken
  Player->>UI: Enter amount and min out
  UI->>AMM: swap(tokenIn, amountIn, minAmountOut)
  AMM->>Oracle: latestPrice()
  Oracle-->>AMM: fresh price
  AMM->>Token: safeTransferFrom(player)
  AMM->>Token: safeTransfer(player)
  AMM-->>UI: Swapped event
```

### Propose, Vote, Execute

```mermaid
sequenceDiagram
  actor Voter
  participant Gov as GameGovernor
  participant Time as TimelockController
  participant Config as GameConfigUpgradeable
  Voter->>Gov: propose(setLegendaryDropBps)
  Voter->>Gov: castVote()
  Gov->>Time: queue()
  Time-->>Gov: eta after 2 days
  Gov->>Time: execute()
  Time->>Config: setLegendaryDropBps()
```

### Craft Item

```mermaid
sequenceDiagram
  actor Player
  participant Craft as CraftingSystem
  participant Items as GameItems
  Player->>Craft: craft(recipeId)
  Craft->>Items: burn resources
  Craft->>Items: mint equipment
  Craft-->>Player: Crafted event
```

## Storage Layout

- `GameConfigUpgradeable`: `craftingFeeBps`, `legendaryDropBps`, `oracleStaleAfter`, `__gap`. V2 adds `rentalFeeBps` after the reserved V1 layout, preventing collision.
- `ResourceAMM`: immutable token addresses, oracle address, LP ERC20 storage inherited from OpenZeppelin.
- `RentalVault`: `nextRentalId`, `rentals`, ERC4626 share accounting.
- `CraftingSystem`: `nextRecipeId`, `recipes`.
- `LootDrop`: VRF config, `legendaryDropBps`, `requestPlayer`.

## Trust Assumptions

The Timelock is the owner/admin for protocol parameters. Individual deployer admin rights are revoked after deployment. If the Timelock is compromised, the attacker can change drop rates, pause or unpause configurable modules, and upgrade the UUPS implementation after the delay.

## Design Decisions

ADR-001: Use ERC1155 for items because resource stacks and equipment can share one token contract.

ADR-002: Build x\*y=k AMM from scratch because the rubric requires a DeFi primitive rather than a fork.

ADR-003: Use UUPS only for protocol parameters, limiting upgradeable storage risk to a small contract.

ADR-004: Use The Graph for history-heavy views while the dApp reads live balances directly from contracts.
