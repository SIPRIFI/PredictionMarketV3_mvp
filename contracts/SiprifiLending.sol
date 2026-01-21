// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./SiprifiVault.sol";
import "./SiprifiStablecoin.sol";

contract SiprifiLending {
    SiprifiVault public vault;
    SiprifiStablecoin public stablecoin;

    mapping(address => uint256) public userDebt;

    constructor(address _vault) {
        vault = SiprifiVault(_vault);

        // Create stablecoin, this contract becomes owner
        stablecoin = new SiprifiStablecoin();
    }

    function borrow(uint256 amount) external {
        require(amount > 0, "amount zero");

        uint256 ebp = vault.getAccountEBP(msg.sender);
        require(userDebt[msg.sender] + amount <= ebp, "Insolvent");

        userDebt[msg.sender] += amount;
        stablecoin.mint(msg.sender, amount);
    }

    function repay(uint256 amount) external {
        require(amount > 0, "amount zero");
        require(userDebt[msg.sender] > 0, "no debt");

        // User sends sipUSD to this contract
        stablecoin.transferFrom(msg.sender, address(this), amount);

        // Burn from this contract balance
        stablecoin.burn(address(this), amount);

        if (amount >= userDebt[msg.sender]) {
            userDebt[msg.sender] = 0;
        } else {
            userDebt[msg.sender] -= amount;
        }
    }
}
