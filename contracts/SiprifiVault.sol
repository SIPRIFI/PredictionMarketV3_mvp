// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SiprifiRiskEngine.sol";

contract SiprifiVault is Ownable {
    SiprifiRiskEngine public riskEngine;
    address public lending;

    uint256 public constant LTV_BASE = 10_000;
    uint256 public constant MAX_GROUPS = 32;
    uint256 public constant MIN_LTV = 100;

    struct AssetConfig {
        address token;
        uint256 ltv;
        uint256 correlatedGroup;
        bool enabled;
    }

    // user => token => balance
    mapping(address => mapping(address => uint256)) public collateralBalance;

    // token => asset config
    mapping(address => AssetConfig) public assetConfig;

    // indexed list for frontend
    address[] public supportedAssets;

    /* ================= EVENTS ================= */

    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdraw(address indexed user, address indexed token, uint256 amount);
    event AssetAdded(address token, uint256 ltv, uint256 group);

    constructor(address _riskEngine) Ownable() {
        riskEngine = SiprifiRiskEngine(_riskEngine);
    }

    /* ================= ADMIN ================= */

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
        require(ltv >= MIN_LTV, "ltv too low");
        require(ltv <= LTV_BASE, "ltv too high");
        require(correlatedGroup < MAX_GROUPS, "group out");

        assetConfig[token] = AssetConfig({
            token: token,
            ltv: ltv,
            correlatedGroup: correlatedGroup,
            enabled: true
        });

        supportedAssets.push(token);

        emit AssetAdded(token, ltv, correlatedGroup);
    }

    /* ================= FRONTEND HELPERS ================= */

    function assetCount() external view returns (uint256) {
        return supportedAssets.length;
    }

    function assets(uint256 index)
        external
        view
        returns (
            address token,
            uint256 ltv,
            uint256 group,
            bool enabled
        )
    {
        address t = supportedAssets[index];
        AssetConfig memory cfg = assetConfig[t];
        return (cfg.token, cfg.ltv, cfg.correlatedGroup, cfg.enabled);
    }

    function getSupportedAssets() external view returns (address[] memory) {
        return supportedAssets;
    }

    /* ================= USER ACTIONS ================= */

    function depositCollateral(address token, uint256 amount) external {
        AssetConfig memory cfg = assetConfig[token];
        require(cfg.enabled, "asset not supported");
        require(amount > 0, "amount zero");

        IERC20(token).transferFrom(msg.sender, address(this), amount);
        collateralBalance[msg.sender][token] += amount;

        emit Deposit(msg.sender, token, amount);
    }

    function withdrawCollateral(
        address user,
        address token,
        uint256 amount
    ) external onlyLending {
        require(collateralBalance[user][token] >= amount, "insufficient");

        collateralBalance[user][token] -= amount;
        IERC20(token).transfer(user, amount);

        emit Withdraw(user, token, amount);
    }

    /* ================= BORROWING POWER ================= */

    function getAccountEBP(address user) external view returns (uint256) {
        uint256 baseBorrowingPower;
        uint256[] memory groupExposure = new uint256[](MAX_GROUPS);

        for (uint256 i = 0; i < supportedAssets.length; i++) {
            address token = supportedAssets[i];
            uint256 balance = collateralBalance[user][token];
            if (balance == 0) continue;

            AssetConfig memory cfg = assetConfig[token];
            if (!cfg.enabled) continue;

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
