// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract GameItems is ERC1155, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    uint256 public constant WOOD = 1;
    uint256 public constant IRON = 2;
    uint256 public constant CRYSTAL = 3;
    uint256 public constant SWORD = 100;
    uint256 public constant ARMOR = 101;
    uint256 public constant LEGENDARY_RELIC = 777;

    constructor(address admin, string memory uri_) ERC1155(uri_) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(BURNER_ROLE, admin);
    }

    function mint(address to, uint256 id, uint256 amount, bytes calldata data)
        external
        onlyRole(MINTER_ROLE)
    {
        _mint(to, id, amount, data);
    }

    function burn(address from, uint256 id, uint256 amount) external onlyRole(BURNER_ROLE) {
        _burn(from, id, amount);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

