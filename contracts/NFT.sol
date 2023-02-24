// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

//@author : rcheiko

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";
import "./IERC721A.sol";
import "./extensions/ERC721AQueryable.sol";
import "./extensions/IERC721AQueryable.sol";

contract RiskNftERC721A is Ownable, ERC721A, ERC721AQueryable {
    using Strings for uint256;

    enum Step {
        Before,
        WhitelistSale,
        PublicSale,
        SoldOut,
        Reveal
    }

    string public baseURI;

    Step public sellingStep;
    uint256 private constant MAX_SUPPLY = 10000;
    uint256 private constant MAX_WHITELIST = 1000;
    uint256 private constant MAX_PUBLIC = 8900;
    uint256 private constant MAX_GIFT = 100;

    uint256 public wlSalePrice = 0.001 ether; // 3 matic
    uint256 public publicSalePrice = 0.002 ether; // 5 matic

    bytes32 public merkleRoot;

    mapping(address => uint256) public amountNFTsPerWalletWhitelistSale;
    mapping(address => uint256) public amountNFTsPerWalletPublicSale;

    address private team;

    constructor(
        address _team,
        bytes32 _merklesRoot,
        string memory _baseURI
    ) ERC721A("R2E", "R2E") {
        merkleRoot = _merklesRoot;
        baseURI = _baseURI;
        team = _team;
    }

    modifier callerIsUser() {
        require(msg.sender == tx.origin, "The caller is not user");
        _;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function isWhiteListed(address _account, bytes32[] calldata _proof)
        internal
        view
        returns (bool)
    {
        return _verify(leaf(_account), _proof);
    }

    function leaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function _verify(bytes32 _leaf, bytes32[] calldata _proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

    function setStep(uint256 _step) external onlyOwner {
        sellingStep = Step(_step);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    function gift(address _to, uint256 _quantity) external onlyOwner {
        require(sellingStep == Step.PublicSale, "Gift is after Public Sale");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Gift is sold out");
        _safeMint(_to, _quantity);
    }

    function whitelistMint(uint256 _quantity, bytes32[] calldata _proof)
        external
        payable
        callerIsUser
    {
        uint256 price = wlSalePrice * _quantity;
        require(price != 0, "Price is zero");
        require(
            sellingStep == Step.WhitelistSale,
            "Whitelist sale is not started"
        );
        require(isWhiteListed(msg.sender, _proof), "You are not whitelisted");
        require(
            amountNFTsPerWalletWhitelistSale[msg.sender] + _quantity <= 3,
            "You can buy max 3 NFTs on the whitelist sale"
        );
        require(
            totalSupply() + _quantity <= MAX_WHITELIST,
            "Whitelist sale is sold out"
        );
        require(msg.value == price, "Incorrect price");
        amountNFTsPerWalletWhitelistSale[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function publicSaleMint(uint256 _quantity) external payable callerIsUser {
        uint256 price = publicSalePrice * _quantity;
        require(price != 0, "Price is zero");
        require(sellingStep == Step.PublicSale, "Public sale is not started");
        require(
            amountNFTsPerWalletPublicSale[msg.sender] + _quantity <= 10,
            "You can buy max 10 NFTs on the public sale"
        );
        require(
            totalSupply() + _quantity <= MAX_PUBLIC + MAX_WHITELIST,
            "Public sale is sold out"
        );
        require(msg.value == price, "Incorrect price");
        amountNFTsPerWalletPublicSale[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }
}
