// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract YulMathBench {
    function minSolidity(uint256 a, uint256 b) external pure returns (uint256) {
        return a < b ? a : b;
    }

    function minYul(uint256 a, uint256 b) external pure returns (uint256 result) {
        assembly {
            result := xor(b, mul(xor(a, b), lt(a, b)))
        }
    }
}

