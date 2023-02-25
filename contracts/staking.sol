// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./NFT.sol";
import "./token.sol";

contract stakingNft is Ownable {
    uint256 public totalStaked;

    struct Staking {
        uint24 tokenId;
        uint256 stakingStartTime;
        address owner;
    }

    mapping(uint256 => Staking) public NFTsStaked;

    uint256 rewardsPerHour = 10;

    NftERC721A nft;
    tokenERC20 token;

    event Staked(
        address indexed owner,
        uint24 tokenId,
        uint256 stakingStartTime
    );
    event Unstaked(
        address indexed owner,
        uint24 tokenId,
        uint256 stakingEndTime,
        uint256 stakingEndTime,
        uint256 rewards
    );
    event Claimed(address indexed owner, uint24 tokenId, uint256 rewards);

    constructor(address _nft, address _token) {
        nft = NftERC721A(_nft);
        token = tokenERC20(_token);
    }

    function stake(uint256[] calldata tokenIds) external {
        require(
            tokenIds.length <= 10,
            "You can't stake more than 10 NFTs at once"
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                nft.ownerOf(tokenIds[i]) == msg.sender,
                "You are not the owner of this NFT"
            );
            require(
                NFTsStaked[tokenIds[i]].stakingStartTime == 0,
                "This NFT is already staked"
            );

            nft.transferFrom(msg.sender, address(this), tokenIds[i]);

            NFTsStaked[tokenIds[i]] = Staking(
                uint24(tokenIds[i]),
                block.timestamp,
                msg.sender
            );

            totalStaked++;

            emit Staked(msg.sender, uint24(tokenIds[i]), block.timestamp);
        }
    }

    function unstake(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                NFTsStaked[tokenIds[i]].owner == msg.sender,
                "You are not the owner of this NFT"
            );
            require(
                nft.ownerOf(tokenIds[i]) == address(this),
                "This NFT is not staked"
            );

            uint256 stakingEndTime = block.timestamp;
            uint256 rewards = (((stakingEndTime -
                NFTsStaked[tokenIds[i]].stakingStartTime) * rewardsPerHour) /
                3600) * 10**18;

            delete NFTsStaked[tokenIds[i]];

            nft.transferFrom(address(this), msg.sender, tokenIds[i]);
            token.mint(msg.sender, rewards);

            totalStaked--;

            emit Unstaked(
                msg.sender,
                uint24(tokenIds[i]),
                stakingEndTime,
                rewards
            );
        }
    }


    function claim(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                NFTsStaked[tokenIds[i]].owner == msg.sender,
                "You are not the owner of this NFT"
            );
            require(
                nft.ownerOf(tokenIds[i]) == address(this),
                "This NFT is not staked"
            );

            uint256 stakingEndTime = block.timestamp;
            uint256 rewards = (((stakingEndTime -
                NFTsStaked[tokenIds[i]].stakingStartTime) * rewardsPerHour) /
                3600) * 10**18;

            token.mint(msg.sender, rewards);

            NFTsStaked[tokenIds[i]].stakingStartTime = stakingEndTime;

            emit Claimed(msg.sender, uint24(tokenIds[i]), rewards);
        }
    }
}
