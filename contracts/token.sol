// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract tokenERC20 is ERC20, Ownable, AccessControl {

    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE"); // MINT ROLE TO CALL mint in different smart contract

    constructor() ERC20("riskToken", "RT") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(address _to, uint _amount) external onlyRole(MINT_ROLE) {
        require(hasRole(MINT_ROLE, msg.sender));
        _mint(_to, _amount);
    }

    function burn(uint _amount) external {
        _burn(msg.sender, _amount);
    }
}
