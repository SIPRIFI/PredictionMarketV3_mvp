// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./PredictionMarketV2.sol";
import "./SiprifiRiskEngine.sol";

contract SiprifiVault is Ownable {
    PredictionMarketV2 public marketFactory;
    SiprifiRiskEngine public riskEngine;
    mapping(address => mapping(address => uint256)) public collateralBalance;
    mapping(address => bool) public isWhitelisted;

    constructor(address _marketFactory, address _riskEngine) Ownable() {
        marketFactory = PredictionMarketV2(payable(_marketFactory));
        riskEngine = SiprifiRiskEngine(_riskEngine);
    }

    function whitelistToken(address token, bool status) external onlyOwner {
        isWhitelisted[token] = status;
    }

    function depositCollateral(address token, uint256 amount) external {
        require(isWhitelisted[token], "Not whitelisted");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        collateralBalance[msg.sender][token] += amount;
    }

    function getAccountEBP(address user, uint256[] memory currentPositionValues) public view returns (uint256) {
        uint256 totalBasePower = 0;
        for (uint256 i = 0; i < currentPositionValues.length; i++) {
            totalBasePower += (currentPositionValues[i] * 50) / 100; // 50% LTV
        }
        return riskEngine.calculateEBP(totalBasePower, currentPositionValues);
    }
}