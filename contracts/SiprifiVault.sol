// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SiprifiRiskEngine.sol";

contract SiprifiVault is Ownable {
    SiprifiRiskEngine public riskEngine;
    address public lending; // contrato autorizado

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
    event Withdraw(address indexed user, address indexed token, uint256 amount);

    constructor(address _riskEngine) Ownable() {
        riskEngine = SiprifiRiskEngine(_riskEngine);
    }

    function setLending(address _lending) external onlyOwner {
        lending = _lending;
    }

    modifier onlyLending() {
        require(msg.sender == lending, "not lending");
        _;
    }

    function addAsset(
        address token,
        uint256 ltv,
        uint256 correlatedGroup
    ) external onlyOwner {
        require(!assetConfig[token].enabled, "asset exists");
        require(ltv <= LTV_BASE, "invalid ltv");
        require(correlatedGroup < MAX_GROUPS, "group out");

        assetConfig[token] = AssetConfig(true, ltv, correlatedGroup);
        supportedAssets.push(token);
    }

    function depositCollateral(address token, uint256 amount) external {
        require(assetConfig[token].enabled, "asset not supported");
        require(amount > 0, "amount zero");

        IERC20(token).transferFrom(msg.sender, address(this), amount);
        collateralBalance[msg.sender][token] += amount;

        emit Deposit(msg.sender, token, amount);
    }

    // 🔐 Withdraw solo autorizado por Lending
    function withdrawCollateral(
        address user,
        address token,
        uint256 amount
    ) external onlyLending {
        collateralBalance[user][token] -= amount;
        IERC20(token).transfer(user, amount);
        emit Withdraw(user, token, amount);
    }

    function getSupportedAssets() external view returns (address[] memory) {
        return supportedAssets;
    }

    function getAccountEBP(address user) external view returns (uint256) {
        uint256 baseBorrowingPower;
        uint256[] memory groupExposure = new uint256[](MAX_GROUPS);

        for (uint256 i = 0; i < supportedAssets.length; i++) {
            address token = supportedAssets[i];
            uint256 balance = collateralBalance[user][token];
            if (balance == 0) continue;

            AssetConfig memory cfg = assetConfig[token];
            uint256 ltvValue = (balance * cfg.ltv) / LTV_BASE;

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
