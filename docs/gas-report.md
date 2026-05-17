# Gas Optimization Report Draft

| Operation           | Baseline | Optimized | Notes                                      |
| ------------------- | -------: | --------: | ------------------------------------------ |
| AMM addLiquidity    |      TBD |       TBD | Benchmark after `REPORT_GAS=true npm test` |
| AMM swap            |      TBD |       TBD | Yul min used in LP share calculation       |
| AMM removeLiquidity |      TBD |       TBD | SafeERC20 retained despite small overhead  |
| Craft item          |      TBD |       TBD | Loop cost scales with recipe inputs        |
| Rental list         |      TBD |       TBD | ERC1155 transfer dominates                 |
| Governance vote     |      TBD |       TBD | OpenZeppelin Governor baseline             |

## L1 vs L2 Comparison

| Operation        | Ethereum Sepolia Gas | Base Sepolia Gas | Difference |
| ---------------- | -------------------: | ---------------: | ---------: |
| Deploy GameToken |                  TBD |              TBD |        TBD |
| Add liquidity    |                  TBD |              TBD |        TBD |
| Swap             |                  TBD |              TBD |        TBD |
| Craft            |                  TBD |              TBD |        TBD |
| Propose          |                  TBD |              TBD |        TBD |
| Cast vote        |                  TBD |              TBD |        TBD |
