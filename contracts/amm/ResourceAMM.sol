// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IStaleCheckedOracle {
    function latestPrice() external view returns (int256 price, uint8 decimals);
}

contract ResourceAMM is ERC20, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant FEE_BPS = 30;
    uint256 public constant BPS = 10_000;

    IERC20 public immutable token0;
    IERC20 public immutable token1;
    IStaleCheckedOracle public oracle;

    event LiquidityAdded(address indexed provider, uint256 amount0, uint256 amount1, uint256 shares);
    event LiquidityRemoved(address indexed provider, uint256 amount0, uint256 amount1, uint256 shares);
    event Swapped(address indexed trader, address indexed tokenIn, uint256 amountIn, uint256 amountOut);
    event OracleUpdated(address indexed oracle);

    constructor(address owner_, IERC20 token0_, IERC20 token1_, IStaleCheckedOracle oracle_)
        ERC20("GameFi LP", "GFLP")
        Ownable(owner_)
    {
        require(address(token0_) != address(token1_), "same token");
        token0 = token0_;
        token1 = token1_;
        oracle = oracle_;
    }

    function setOracle(IStaleCheckedOracle newOracle) external onlyOwner {
        oracle = newOracle;
        emit OracleUpdated(address(newOracle));
    }

    function addLiquidity(uint256 amount0, uint256 amount1, uint256 minShares)
        external
        nonReentrant
        returns (uint256 shares)
    {
        require(amount0 > 0 && amount1 > 0, "zero amount");
        uint256 reserve0 = token0.balanceOf(address(this));
        uint256 reserve1 = token1.balanceOf(address(this));
        uint256 supply = totalSupply();

        if (supply == 0) {
            shares = _sqrt(amount0 * amount1);
        } else {
            shares = _min((amount0 * supply) / reserve0, (amount1 * supply) / reserve1);
        }
        require(shares >= minShares && shares > 0, "slippage");

        token0.safeTransferFrom(msg.sender, address(this), amount0);
        token1.safeTransferFrom(msg.sender, address(this), amount1);
        _mint(msg.sender, shares);
        emit LiquidityAdded(msg.sender, amount0, amount1, shares);
    }

    function removeLiquidity(uint256 shares, uint256 minAmount0, uint256 minAmount1)
        external
        nonReentrant
        returns (uint256 amount0, uint256 amount1)
    {
        require(shares > 0, "zero shares");
        uint256 supply = totalSupply();
        amount0 = (shares * token0.balanceOf(address(this))) / supply;
        amount1 = (shares * token1.balanceOf(address(this))) / supply;
        require(amount0 >= minAmount0 && amount1 >= minAmount1, "slippage");

        _burn(msg.sender, shares);
        token0.safeTransfer(msg.sender, amount0);
        token1.safeTransfer(msg.sender, amount1);
        emit LiquidityRemoved(msg.sender, amount0, amount1, shares);
    }

    function swap(address tokenIn, uint256 amountIn, uint256 minAmountOut)
        external
        nonReentrant
        returns (uint256 amountOut)
    {
        require(tokenIn == address(token0) || tokenIn == address(token1), "bad token");
        require(amountIn > 0, "zero amount");
        if (address(oracle) != address(0)) {
            oracle.latestPrice();
        }

        bool zeroForOne = tokenIn == address(token0);
        IERC20 inToken = zeroForOne ? token0 : token1;
        IERC20 outToken = zeroForOne ? token1 : token0;
        uint256 reserveIn = inToken.balanceOf(address(this));
        uint256 reserveOut = outToken.balanceOf(address(this));
        uint256 amountInWithFee = amountIn * (BPS - FEE_BPS);

        amountOut = (amountInWithFee * reserveOut) / (reserveIn * BPS + amountInWithFee);
        require(amountOut >= minAmountOut && amountOut > 0, "slippage");

        inToken.safeTransferFrom(msg.sender, address(this), amountIn);
        outToken.safeTransfer(msg.sender, amountOut);
        emit Swapped(msg.sender, tokenIn, amountIn, amountOut);
    }

    function getAmountOut(address tokenIn, uint256 amountIn) external view returns (uint256) {
        bool zeroForOne = tokenIn == address(token0);
        require(zeroForOne || tokenIn == address(token1), "bad token");
        uint256 reserveIn = (zeroForOne ? token0 : token1).balanceOf(address(this));
        uint256 reserveOut = (zeroForOne ? token1 : token0).balanceOf(address(this));
        uint256 amountInWithFee = amountIn * (BPS - FEE_BPS);
        return (amountInWithFee * reserveOut) / (reserveIn * BPS + amountInWithFee);
    }

    function reserves() external view returns (uint256 reserve0, uint256 reserve1) {
        return (token0.balanceOf(address(this)), token1.balanceOf(address(this)));
    }

    function _sqrt(uint256 x) private pure returns (uint256 y) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function _min(uint256 a, uint256 b) private pure returns (uint256 result) {
        assembly {
            result := xor(b, mul(xor(a, b), lt(a, b)))
        }
    }
}

