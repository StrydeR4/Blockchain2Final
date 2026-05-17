# Required GraphQL Queries

```graphql
query RecentSwaps {
  swaps(first: 10, orderBy: timestamp, orderDirection: desc) {
    id
    trader
    tokenIn
    amountIn
    amountOut
    timestamp
  }
}
```

```graphql
query PoolState {
  pool(id: "gamefi-resource-pool") {
    reserve0
    reserve1
    totalSwaps
    totalLiquidityEvents
  }
}
```

```graphql
query LiquidityPositions {
  liquidityPositions(first: 20, orderBy: updatedAt, orderDirection: desc) {
    provider
    shares
    updatedAt
  }
}
```

```graphql
query ActiveProposals {
  proposals(first: 10, orderBy: createdAt, orderDirection: desc) {
    id
    proposer
    description
    state
  }
}
```

```graphql
query ProposalVotes($id: ID!) {
  proposal(id: $id) {
    id
    description
    votes {
      voter
      support
      weight
      reason
    }
  }
}
```
