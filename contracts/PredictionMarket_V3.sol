// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./MarketToken.sol";
import "./ISiprifiLending.sol";

contract PredictionMarketV3 {
    uint256 public marketCount;
    ISiprifiLending public immutable siprifiLending;

    enum MarketStatus { InProgress, Occurred }

    event MarketCreated(uint256 indexed marketId, string question, uint256 deadline, address yesToken, address noToken);
    event SharesPurchased(uint256 indexed marketId, address indexed buyer, uint256 amount);
    event MarketResolved(uint256 indexed marketId, uint8 outcome);
    event RewardClaimed(uint256 indexed marketId, address indexed user, uint256 amount);

    struct Market {
        address owner;
        uint256 deadline;
        bool resolved;
        uint8 outcome;
        address yesToken;
        address noToken;
        uint256 escrow;
        bool exists;
    }

    mapping(uint256 => Market) public markets;

    constructor(address _siprifiLending) {
        siprifiLending = ISiprifiLending(_siprifiLending);
    }

    modifier onlyOwner(uint256 marketId) {
        require(msg.sender == markets[marketId].owner, "Not owner");
        _;
    }

    modifier marketExists(uint256 marketId) {
        require(markets[marketId].exists, "Market not found");
        _;
    }

    function createMarket(string memory question, uint256 deadline) external returns (uint256) {
        require(deadline > block.timestamp, "Invalid deadline");

        uint256 id = ++marketCount;

        MarketToken yes = new MarketToken(
            string(abi.encodePacked("YES-", uint2str(id))),
            "YES",
            msg.sender,
            address(this),
            address(siprifiLending),
            id,
            false
        );

        MarketToken no = new MarketToken(
            string(abi.encodePacked("NO-", uint2str(id))),
            "NO",
            msg.sender,
            address(this),
            address(siprifiLending),
            id,
            true
        );

        markets[id] = Market({
            owner: msg.sender,
            deadline: deadline,
            resolved: false,
            outcome: 2,
            yesToken: address(yes),
            noToken: address(no),
            escrow: 0,
            exists: true
        });

        emit MarketCreated(id, question, deadline, address(yes), address(no));
        return id;
    }

    function buyYesShares(uint256 marketId) external payable marketExists(marketId) {
        Market storage m = markets[marketId];
        require(block.timestamp < m.deadline, "Closed");
        require(msg.value > 0, "No ETH");

        m.escrow += msg.value;

        MarketToken(m.yesToken).mint(msg.sender, msg.value);
        MarketToken(m.noToken).mint(m.owner, msg.value);

        emit SharesPurchased(marketId, msg.sender, msg.value);
    }

    function resolveMarket(uint256 marketId, uint8 outcome)
        external
        onlyOwner(marketId)
        marketExists(marketId)
    {
        Market storage m = markets[marketId];
        require(block.timestamp >= m.deadline, "Too early");
        require(!m.resolved, "Resolved");
        require(outcome == 0 || outcome == 1, "Bad outcome");

        m.resolved = true;
        m.outcome = outcome;

        // YES gana → habilitar transfers YES
        if (outcome == 1) {
            MarketToken(m.yesToken).enableTransfers();
            MarketToken(m.noToken).disableCollateral();
        } else {
            MarketToken(m.noToken).disableCollateral();
        }

        emit MarketResolved(marketId, outcome);
    }

    function claimReward(uint256 marketId) external marketExists(marketId) {
        Market storage m = markets[marketId];
        require(m.resolved, "Not resolved");

        address winningToken = m.outcome == 1 ? m.yesToken : m.noToken;
        MarketToken token = MarketToken(winningToken);

        uint256 bal = token.balanceOf(msg.sender);
        require(bal > 0, "No balance");

        uint256 payout = (m.escrow * bal) / token.totalSupply();
        m.escrow -= payout;

        token.burn(msg.sender, bal);
        payable(msg.sender).transfer(payout);

        emit RewardClaimed(marketId, msg.sender, payout);
    }

    function uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) return "0";
        uint256 j = _i;
        uint256 length;
        while (j != 0) { length++; j /= 10; }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        while (_i != 0) {
            k--;
            bstr[k] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    receive() external payable {}
}
