// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

contract GameConfigUpgradeable is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable
{
    bytes32 public constant PARAMETER_ROLE = keccak256("PARAMETER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint256 public craftingFeeBps;
    uint256 public legendaryDropBps;
    uint256 public oracleStaleAfter;
    uint256[47] private __gap;

    event CraftingFeeUpdated(uint256 oldFeeBps, uint256 newFeeBps);
    event LegendaryDropUpdated(uint256 oldDropBps, uint256 newDropBps);
    event OracleStaleAfterUpdated(uint256 oldWindow, uint256 newWindow);

    function initialize(address timelock) external initializer {
        __AccessControl_init();
        __Pausable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, timelock);
        _grantRole(PARAMETER_ROLE, timelock);
        _grantRole(PAUSER_ROLE, timelock);
        craftingFeeBps = 50;
        legendaryDropBps = 100;
        oracleStaleAfter = 1 hours;
    }

    function setCraftingFeeBps(uint256 newFeeBps) external onlyRole(PARAMETER_ROLE) {
        require(newFeeBps <= 1_000, "fee too high");
        emit CraftingFeeUpdated(craftingFeeBps, newFeeBps);
        craftingFeeBps = newFeeBps;
    }

    function setLegendaryDropBps(uint256 newDropBps) external onlyRole(PARAMETER_ROLE) {
        require(newDropBps <= 10_000, "drop too high");
        emit LegendaryDropUpdated(legendaryDropBps, newDropBps);
        legendaryDropBps = newDropBps;
    }

    function setOracleStaleAfter(uint256 newWindow) external onlyRole(PARAMETER_ROLE) {
        require(newWindow >= 5 minutes, "window too short");
        emit OracleStaleAfterUpdated(oracleStaleAfter, newWindow);
        oracleStaleAfter = newWindow;
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
