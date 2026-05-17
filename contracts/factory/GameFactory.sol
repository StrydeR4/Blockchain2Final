// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ResourceToken} from "../tokens/ResourceToken.sol";

contract GameFactory is Ownable {
    event ResourceCreated(address indexed token, string name, string symbol);
    event ResourceCreatedDeterministic(address indexed token, bytes32 indexed salt, string name, string symbol);

    constructor(address owner_) Ownable(owner_) {}

    function createResource(string calldata name, string calldata symbol) external onlyOwner returns (address) {
        ResourceToken token = new ResourceToken(owner(), name, symbol);
        emit ResourceCreated(address(token), name, symbol);
        return address(token);
    }

    function createResourceDeterministic(bytes32 salt, string calldata name, string calldata symbol)
        external
        onlyOwner
        returns (address)
    {
        ResourceToken token = new ResourceToken{salt: salt}(owner(), name, symbol);
        emit ResourceCreatedDeterministic(address(token), salt, name, symbol);
        return address(token);
    }

    function predictResourceAddress(bytes32 salt, string calldata name, string calldata symbol)
        external
        view
        returns (address)
    {
        bytes32 bytecodeHash = keccak256(
            abi.encodePacked(type(ResourceToken).creationCode, abi.encode(owner(), name, symbol))
        );
        return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, bytecodeHash)))));
    }
}

