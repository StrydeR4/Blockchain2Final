// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {GameItems} from "../tokens/GameItems.sol";

contract CraftingSystem is AccessControl, ReentrancyGuard {
    bytes32 public constant DESIGNER_ROLE = keccak256("DESIGNER_ROLE");

    struct Recipe {
        uint256 outputId;
        uint256 outputAmount;
        uint256[] inputIds;
        uint256[] inputAmounts;
        bool active;
    }

    GameItems public immutable items;
    uint256 public nextRecipeId;
    mapping(uint256 recipeId => Recipe) public recipes;

    event RecipeCreated(uint256 indexed recipeId, uint256 indexed outputId);
    event RecipeStatusChanged(uint256 indexed recipeId, bool active);
    event Crafted(address indexed player, uint256 indexed recipeId, uint256 outputId, uint256 amount);

    constructor(address admin, GameItems items_) {
        items = items_;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(DESIGNER_ROLE, admin);
    }

    function createRecipe(
        uint256 outputId,
        uint256 outputAmount,
        uint256[] calldata inputIds,
        uint256[] calldata inputAmounts
    ) external onlyRole(DESIGNER_ROLE) returns (uint256 recipeId) {
        require(inputIds.length == inputAmounts.length && inputIds.length > 0, "bad inputs");
        recipeId = nextRecipeId++;
        recipes[recipeId] = Recipe(outputId, outputAmount, inputIds, inputAmounts, true);
        emit RecipeCreated(recipeId, outputId);
    }

    function setRecipeActive(uint256 recipeId, bool active) external onlyRole(DESIGNER_ROLE) {
        recipes[recipeId].active = active;
        emit RecipeStatusChanged(recipeId, active);
    }

    function craft(uint256 recipeId) external nonReentrant {
        Recipe storage recipe = recipes[recipeId];
        require(recipe.active, "inactive recipe");

        for (uint256 i = 0; i < recipe.inputIds.length; i++) {
            items.burn(msg.sender, recipe.inputIds[i], recipe.inputAmounts[i]);
        }

        items.mint(msg.sender, recipe.outputId, recipe.outputAmount, "");
        emit Crafted(msg.sender, recipeId, recipe.outputId, recipe.outputAmount);
    }
}

