// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SiprifiRiskEngine.sol";

contract SiprifiVault is Ownable {
    SiprifiRiskEngine public riskEngine;

    struct AssetConfig {
        bool enabled;
        uint256 ltv;
        uint256 correlatedGroup;
    }

    mapping(address => mapping(address => uint256)) public collateralBalance;
    mapping(address => AssetConfig) public assetConfig;
    address[] public supportedAssets;

    uint256 public constant LTV_BASE = 10_000;
    uint256 public constant MAX_GROUPS = 32;

    event Deposit(address indexed user, address indexed token, uint256 amount);

    constructor(address _riskEngine) Ownable() {
        riskEngine = SiprifiRiskEngine(_riskEngine);
    }

    function addAsset(
        address token,
        uint256 ltv,
        uint256 correlatedGroup
    ) external onlyOwner {
        require(!assetConfig[token].enabled, "asset exists");
        require(ltv <= LTV_BASE, "invalid ltv");
        require(correlatedGroup < MAX_GROUPS, "group out of bounds");

        assetConfig[token] = AssetConfig({
            enabled: true,
            ltv: ltv,
            correlatedGroup: correlatedGroup
        });

        supportedAssets.push(token);
    }

    function depositCollateral(address token, uint256 amount) external {
        AssetConfig memory cfg = assetConfig[token];
        require(cfg.enabled, "asset not supported");
        require(amount > 0, "amount zero");

        bool ok = IERC20(token).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        require(ok, "transfer failed");

        collateralBalance[msg.sender][token] += amount;

        emit Deposit(msg.sender, token, amount);
    }

    function getAccountEBP(
        address user,
        uint256[] calldata prices
    ) external view returns (uint256) {
        require(prices.length == supportedAssets.length, "price length mismatch");

        uint256 baseBorrowingPower;
        uint256[] memory groupExposure = new uint256[](MAX_GROUPS);

        for (uint256 i = 0; i < supportedAssets.length; i++) {
            address token = supportedAssets[i];
            uint256 balance = collateralBalance[user][token];
            if (balance == 0) continue;

            AssetConfig memory cfg = assetConfig[token];
            uint256 value = balance * prices[i];
            uint256 ltvValue = (value * cfg.ltv) / LTV_BASE;

            baseBorrowingPower += ltvValue;
            groupExposure[cfg.correlatedGroup] += ltvValue;
        }

        uint256 count;
        for (uint256 i = 0; i < MAX_GROUPS; i++) {
            if (groupExposure[i] > 0) count++;
        }

        uint256[] memory groupValues = new uint256[](count);
        uint256 idx;
        for (uint256 i = 0; i < MAX_GROUPS; i++) {
            if (groupExposure[i] > 0) {
                groupValues[idx++] = groupExposure[i];
            }
        }

        return riskEngine.calculateEBP(baseBorrowingPower, groupValues);
    }
}
