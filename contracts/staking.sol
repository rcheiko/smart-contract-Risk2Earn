// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./NFT.sol";
import "./token.sol";

contract stakingNft is Ownable {

    uint totalStaked;

    struct Staking {
        uint24 tokenId;
        uint256 stakingStartTime;
        address owner;
    }

    mapping(uint256 => Staking) public NFTsStaked;

    constructor() {
    }

}