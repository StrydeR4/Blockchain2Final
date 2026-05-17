// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {GameItems} from "../tokens/GameItems.sol";

contract LootDrop is VRFConsumerBaseV2Plus, AccessControl, ReentrancyGuard {
    bytes32 public constant LOOT_ADMIN_ROLE = keccak256("LOOT_ADMIN_ROLE");

    GameItems public immutable items;
    uint256 public immutable subscriptionId;
    bytes32 public immutable keyHash;
    uint32 public callbackGasLimit = 200_000;
    uint16 public requestConfirmations = 3;
    uint256 public legendaryDropBps = 100;

    mapping(uint256 requestId => address player) public requestPlayer;

    event LootRequested(uint256 indexed requestId, address indexed player);
    event LootFulfilled(uint256 indexed requestId, address indexed player, uint256 itemId);
    event DropRateUpdated(uint256 oldDropBps, uint256 newDropBps);

    constructor(
        address admin,
        address coordinator,
        GameItems items_,
        uint256 subscriptionId_,
        bytes32 keyHash_
    ) VRFConsumerBaseV2Plus(coordinator) {
        items = items_;
        subscriptionId = subscriptionId_;
        keyHash = keyHash_;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(LOOT_ADMIN_ROLE, admin);
    }

    function requestLoot() external nonReentrant returns (uint256 requestId) {
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: 1,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
        requestPlayer[requestId] = msg.sender;
        emit LootRequested(requestId, msg.sender);
    }

    function setLegendaryDropBps(uint256 newDropBps) external onlyRole(LOOT_ADMIN_ROLE) {
        require(newDropBps <= 10_000, "drop too high");
        emit DropRateUpdated(legendaryDropBps, newDropBps);
        legendaryDropBps = newDropBps;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        address player = requestPlayer[requestId];
        require(player != address(0), "unknown request");
        delete requestPlayer[requestId];

        uint256 roll = randomWords[0] % 10_000;
        uint256 itemId = roll < legendaryDropBps ? items.LEGENDARY_RELIC() : items.CRYSTAL();
        items.mint(player, itemId, 1, "");
        emit LootFulfilled(requestId, player, itemId);
    }
}

