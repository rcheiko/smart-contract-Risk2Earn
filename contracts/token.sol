// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract riskToken is ERC20, Ownable {

    constructor() ERC20("riskToken", "RT") {}

    function mint(address _to, uint _amount) external onlyOwner {
        _mint(_to, _amount * 10 ** 6);
    }

    function burn(uint _amount) external {
        _burn(msg.sender, _amount);
    }
}
