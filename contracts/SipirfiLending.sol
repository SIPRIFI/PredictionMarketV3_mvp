// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./SiprifiVault.sol";

contract SiprifiStablecoin is ERC20 {
    constructor() ERC20("Siprifi USD", "sipUSD") {}
    function mint(address to, uint256 amount) external { _mint(to, amount); }
}

contract SiprifiLending {
    SiprifiVault public vault;
    SiprifiStablecoin public stablecoin;
    mapping(address => uint256) public userDebt;

    constructor(address _vault) {
        vault = SiprifiVault(payable(_vault));
        stablecoin = new SiprifiStablecoin();
    }

    function borrow(uint256 amount, uint256[] memory positionValues) external {
        uint256 ebp = vault.getAccountEBP(msg.sender, positionValues);
        require(userDebt[msg.sender] + amount <= ebp, "Insolvent: Exceeds EBP");
        userDebt[msg.sender] += amount;
        stablecoin.mint(msg.sender, amount);
    }
}