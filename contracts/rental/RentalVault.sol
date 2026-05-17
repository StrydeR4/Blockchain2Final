// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract RentalVault is ERC4626, AccessControl, ERC1155Holder, ReentrancyGuard {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    struct Rental {
        address owner;
        address renter;
        uint256 itemId;
        uint256 amount;
        uint64 expiresAt;
        bool active;
    }

    IERC1155 public immutable items;
    uint256 public nextRentalId;
    mapping(uint256 rentalId => Rental) public rentals;

    event ItemListed(uint256 indexed rentalId, address indexed owner, uint256 indexed itemId, uint256 amount);
    event ItemRented(uint256 indexed rentalId, address indexed renter, uint64 expiresAt);
    event ItemReclaimed(uint256 indexed rentalId);

    constructor(address admin, IERC20 asset_, IERC1155 items_)
        ERC20("GameFi Rental Vault Share", "gRENT")
        ERC4626(asset_)
    {
        items = items_;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);
    }

    function listItem(uint256 itemId, uint256 amount) external nonReentrant returns (uint256 rentalId) {
        require(amount > 0, "zero amount");
        rentalId = nextRentalId++;
        rentals[rentalId] = Rental(msg.sender, address(0), itemId, amount, 0, true);
        items.safeTransferFrom(msg.sender, address(this), itemId, amount, "");
        emit ItemListed(rentalId, msg.sender, itemId, amount);
    }

    function rent(uint256 rentalId, uint64 duration) external nonReentrant {
        Rental storage rental = rentals[rentalId];
        require(rental.active && rental.renter == address(0), "unavailable");
        require(duration <= 14 days && duration > 0, "bad duration");
        rental.renter = msg.sender;
        rental.expiresAt = uint64(block.timestamp) + duration;
        emit ItemRented(rentalId, msg.sender, rental.expiresAt);
    }

    function reclaim(uint256 rentalId) external nonReentrant {
        Rental storage rental = rentals[rentalId];
        require(rental.active, "inactive");
        require(msg.sender == rental.owner, "not owner");
        require(rental.renter == address(0) || block.timestamp >= rental.expiresAt, "still rented");
        rental.active = false;
        items.safeTransferFrom(address(this), rental.owner, rental.itemId, rental.amount, "");
        emit ItemReclaimed(rentalId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl, ERC1155Holder)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
