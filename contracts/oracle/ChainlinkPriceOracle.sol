// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract ChainlinkPriceOracle {
    error StalePrice(uint256 updatedAt, uint256 staleAfter);
    error InvalidPrice();

    AggregatorV3Interface public immutable feed;
    uint256 public immutable staleAfter;

    constructor(address feed_, uint256 staleAfter_) {
        require(feed_ != address(0), "feed zero");
        feed = AggregatorV3Interface(feed_);
        staleAfter = staleAfter_;
    }

    function latestPrice() external view returns (int256 price, uint8 decimals) {
        (, int256 answer,, uint256 updatedAt,) = feed.latestRoundData();
        if (answer <= 0) revert InvalidPrice();
        if (block.timestamp - updatedAt > staleAfter) revert StalePrice(updatedAt, staleAfter);
        return (answer, feed.decimals());
    }
}

