// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./MarketToken.sol";

contract PredictionMarketV2 {
    uint256 public marketCount;
    address public siprifiVault;

    enum MarketStatus { InProgress, Occurred }

    struct Market {
        address owner;
        string question;
        uint256 deadline;
        MarketStatus status;
        bool resolved;
        uint8 outcome; // 0 = NO, 1 = YES
        address yesToken;
        address noToken;
        bool exists;
    }

    mapping(uint256 => Market) public markets;
    mapping(address => uint256) public tokenToMarketId;

    event MarketCreated(uint256 indexed marketId, address yesToken, address noToken);
    event MarketResolved(uint256 indexed marketId, uint8 outcome);
    event RewardClaimed(uint256 indexed marketId, address indexed user, uint256 amount);

    /* ───────── ADMIN ───────── */

    function setVault(address _vault) external {
        siprifiVault = _vault;
    }

    /* ───────── MARKET ───────── */

    function createMarket(string memory question, uint256 deadline) external returns (uint256) {
        require(deadline > block.timestamp, "Invalid deadline");

        uint256 newMarketId = ++marketCount;
        string memory idStr = _uint2str(newMarketId);

        MarketToken yesToken = new MarketToken(
            string.concat("Siprifi YES ", idStr),
            "sYES",
            address(this)
        );

        MarketToken noToken = new MarketToken(
            string.concat("Siprifi NO ", idStr),
            "sNO",
            address(this)
        );

        markets[newMarketId] = Market({
            owner: msg.sender,
            question: question,
            deadline: deadline,
            status: MarketStatus.InProgress,
            resolved: false,
            outcome: 2,
            yesToken: address(yesToken),
            noToken: address(noToken),
            exists: true
        });

        tokenToMarketId[address(yesToken)] = newMarketId;
        tokenToMarketId[address(noToken)] = newMarketId;

        emit MarketCreated(newMarketId, address(yesToken), address(noToken));
        return newMarketId;
    }

    function buyShares(uint256 marketId) external payable {
        Market storage m = markets[marketId];
        require(m.exists, "Market does not exist");
        require(block.timestamp < m.deadline, "Closed");
        require(msg.value > 0, "No ETH sent");

        MarketToken(m.yesToken).mint(msg.sender, msg.value);
        MarketToken(m.noToken).mint(m.owner, msg.value);
    }

    function resolveMarket(uint256 marketId, uint8 _outcome) external {
        Market storage m = markets[marketId];
        require(m.exists, "Market does not exist");
        require(msg.sender == m.owner, "Not owner");
        require(!m.resolved, "Already resolved");
        require(block.timestamp >= m.deadline, "Too early");
        require(_outcome == 0 || _outcome == 1, "Invalid outcome");

        m.resolved = true;
        m.outcome = _outcome;
        m.status = MarketStatus.Occurred;

        emit MarketResolved(marketId, _outcome);
    }

    /* ───────── CLAIM & PAYOUT ───────── */

    function claimReward(uint256 marketId) external {
        Market storage m = markets[marketId];
        require(m.exists, "Market does not exist");
        require(m.resolved, "Not resolved");

        address winningToken = m.outcome == 1 ? m.yesToken : m.noToken;
        MarketToken token = MarketToken(winningToken);

        uint256 userBalance = token.balanceOf(msg.sender);
        require(userBalance > 0, "No winning tokens");

        uint256 totalSupply = token.totalSupply();
        uint256 payout = (address(this).balance * userBalance) / totalSupply;

        token.burn(msg.sender, userBalance);
        payable(msg.sender).transfer(payout);

        emit RewardClaimed(marketId, msg.sender, payout);
    }

    /* ───────── VAULT ───────── */

    function burnFromVault(address token, address account, uint256 amount) external {
        require(msg.sender == siprifiVault, "Only vault");
        MarketToken(token).burn(account, amount);
    }

    /* ───────── UTILS ───────── */

    function _uint2str(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) { digits++; temp /= 10; }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + value % 10));
            value /= 10;
        }
        return string(buffer);
    }

    receive() external payable {}
}
