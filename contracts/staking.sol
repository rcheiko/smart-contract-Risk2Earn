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
    event Claimed(address indexed owner, uint256 rewards);

    constructor(address _nft, address _token) {
        nft = NftERC721A(_nft);
        token = tokenERC20(_token);
    }

    /**
     * @dev Sets the rewards per hour
     * @param _rewardsPerHour The rewards per hour
     */
    function setRewardsPerHour(uint256 _rewardsPerHour) external onlyOwner {
        rewardsPerHour = _rewardsPerHour;
    }

    /**
     * @dev Gets the rewards per hour
     * @param _tokenId The token id
     * @param stakingEndTime The staking end time
     */
    function getRewards(uint256 _tokenId, uint256 stakingEndTime)
        internal
        view
        returns (uint256)
    {
        uint256 rewards = (((stakingEndTime -
            NFTsStaked[_tokenId].stakingStartTime) * rewardsPerHour) / 3600) *
            10**18;
        return rewards;
    }

    /**
     * @dev Stakes NFTs
     * @param tokenIds Array of token ids
     */
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

    /**
     * @dev Unstakes NFTs and claims rewards
     * @param tokenIds Array of token ids
     */
    function unstake(uint256[] calldata tokenIds) external {

        uint256 stakingEndTime = block.timestamp;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                NFTsStaked[tokenIds[i]].owner == msg.sender,
                "You are not the owner of this NFT"
            );
            require(
                nft.ownerOf(tokenIds[i]) == address(this),
                "This NFT is not staked"
            );

            uint256 reward = getRewards(tokenIds[i], stakingEndTime);

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

    /**
     * @dev Claims rewards
     * @param tokenIds Array of token ids
     */
    function claim(uint256[] calldata tokenIds) external {
        uint256 totalRewards;
        uint256 stakingEndTime = block.timestamp;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                NFTsStaked[tokenIds[i]].owner == msg.sender,
                "You are not the owner of this NFT"
            );
            require(
                nft.ownerOf(tokenIds[i]) == address(this),
                "This NFT is not staked"
            );

            uint256 reward = getRewards(tokenIds[i], stakingEndTime);

            totalRewards += rewards;

            NFTsStaked[tokenIds[i]].stakingStartTime = stakingEndTime;
        }

        token.mint(msg.sender, totalRewards);
        emit Claimed(msg.sender, totalRewards);
    }

    /**
     * @dev Gets the total rewards if you claim now
     * @param tokenIds Array of token ids
     */
    function getRewardAmount(uint256[] calldata tokenIds)
        external
        view
        returns (uint256 rewards)
    {
        uint256 totalRewards;
        uint256 stakingEndTime = block.timestamp;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 reward = getRewards(tokenIds[i], stakingEndTime);
            totalRewards += reward;
        }
        return TotalRewards;
    }

    /**
     * @dev Gets all the NFTs staked by the owner
     * @param _owner The address you want to check
     */
    function tokensStakedByOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](totalStaked);
        uint256 counter = 0;
        for (uint256 i = 0; i < totalStaked; i++) {
            if (NFTsStaked[i].owner == _owner) {
                result[counter] = NFTsStaked[i].tokenId;
                counter++;
            }
        }
        return result;
    }
}
