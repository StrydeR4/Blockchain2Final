// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {GameConfigUpgradeable} from "./GameConfigUpgradeable.sol";

contract GameConfigV2 is GameConfigUpgradeable {
    uint256 public rentalFeeBps;

    event RentalFeeUpdated(uint256 oldFeeBps, uint256 newFeeBps);

    function setRentalFeeBps(uint256 newFeeBps) external onlyRole(PARAMETER_ROLE) {
        require(newFeeBps <= 2_000, "fee too high");
        emit RentalFeeUpdated(rentalFeeBps, newFeeBps);
        rentalFeeBps = newFeeBps;
    }

    function version() external pure returns (string memory) {
        return "v2";
    }
}

