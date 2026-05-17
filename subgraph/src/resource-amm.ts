import { BigInt } from "@graphprotocol/graph-ts";
import { LiquidityAdded, LiquidityRemoved, Swapped } from "../../generated/ResourceAMM/ResourceAMM";
import { LiquidityPosition, Pool, Swap } from "../../generated/schema";

const POOL_ID = "gamefi-resource-pool";

function pool(): Pool {
  let entity = Pool.load(POOL_ID);
  if (entity == null) {
    entity = new Pool(POOL_ID);
    entity.reserve0 = BigInt.zero();
    entity.reserve1 = BigInt.zero();
    entity.totalLiquidityEvents = BigInt.zero();
    entity.totalSwaps = BigInt.zero();
  }
  return entity;
}

export function handleLiquidityAdded(event: LiquidityAdded): void {
  let entity = pool();
  entity.reserve0 = entity.reserve0.plus(event.params.amount0);
  entity.reserve1 = entity.reserve1.plus(event.params.amount1);
  entity.totalLiquidityEvents = entity.totalLiquidityEvents.plus(BigInt.fromI32(1));
  entity.save();

  let position = LiquidityPosition.load(event.params.provider.toHexString());
  if (position == null) {
    position = new LiquidityPosition(event.params.provider.toHexString());
    position.provider = event.params.provider;
    position.shares = BigInt.zero();
  }
  position.shares = position.shares.plus(event.params.shares);
  position.updatedAt = event.block.timestamp;
  position.save();
}

export function handleLiquidityRemoved(event: LiquidityRemoved): void {
  let entity = pool();
  entity.reserve0 = entity.reserve0.minus(event.params.amount0);
  entity.reserve1 = entity.reserve1.minus(event.params.amount1);
  entity.totalLiquidityEvents = entity.totalLiquidityEvents.plus(BigInt.fromI32(1));
  entity.save();

  let position = LiquidityPosition.load(event.params.provider.toHexString());
  if (position != null) {
    position.shares = position.shares.minus(event.params.shares);
    position.updatedAt = event.block.timestamp;
    position.save();
  }
}

export function handleSwapped(event: Swapped): void {
  let entity = pool();
  entity.totalSwaps = entity.totalSwaps.plus(BigInt.fromI32(1));
  entity.save();

  let swap = new Swap(
    event.transaction.hash.toHexString().concat("-").concat(event.logIndex.toString())
  );
  swap.trader = event.params.trader;
  swap.tokenIn = event.params.tokenIn;
  swap.amountIn = event.params.amountIn;
  swap.amountOut = event.params.amountOut;
  swap.timestamp = event.block.timestamp;
  swap.save();
}
