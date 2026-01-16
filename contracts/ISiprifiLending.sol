// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ISiprifiLending {
    function depositCollateral(uint256 marketId, address user, uint256 amount) external;
}
