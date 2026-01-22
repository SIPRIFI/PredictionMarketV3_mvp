// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./SiprifiVault.sol";
import "./SiprifiStablecoin.sol";

contract SiprifiLending {
    SiprifiVault public vault;
    SiprifiStablecoin public stablecoin;

    mapping(address => uint256) public userDebt;

    event Borrowed(address indexed user, uint256 amount);
    event Repaid(address indexed user, uint256 amount);

    constructor(address _vault) {
        vault = SiprifiVault(_vault);
        stablecoin = new SiprifiStablecoin();
    }

    function borrow(uint256 amount) external {
        require(amount > 0, "amount zero");

        uint256 ebp = vault.getAccountEBP(msg.sender);
        require(userDebt[msg.sender] + amount <= ebp, "Insolvent");

        userDebt[msg.sender] += amount;
        stablecoin.mint(msg.sender, amount);

        emit Borrowed(msg.sender, amount);
    }

    function repay(uint256 amount) external {
        require(amount > 0, "amount zero");
        require(userDebt[msg.sender] > 0, "no debt");

        uint256 repayAmount = amount > userDebt[msg.sender]
            ? userDebt[msg.sender]
            : amount;

        stablecoin.transferFrom(msg.sender, address(this), repayAmount);
        stablecoin.burn(address(this), repayAmount);

        userDebt[msg.sender] -= repayAmount;

        emit Repaid(msg.sender, repayAmount);
    }
}
