// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SiprifiRiskEngine is Ownable {
    uint256 public N = 1; 

    constructor() Ownable() {}

    function setN(uint256 _n) external onlyOwner {
        N = _n;
    }

    function calculateEBP(uint256 baseBorrowingPower, uint256[] memory groupValues) public view returns (uint256) {
        if (groupValues.length == 0) return baseBorrowingPower;
        uint256[] memory sorted = _sortDescending(groupValues);
        uint256 concentrationOffset = 0;
        for (uint256 i = 0; i < N && i < sorted.length; i++) {
            concentrationOffset += sorted[i];
        }
        return (concentrationOffset >= baseBorrowingPower) ? 0 : baseBorrowingPower - concentrationOffset;
    }

    function _sortDescending(uint256[] memory arr) internal pure returns (uint256[] memory) {
        for (uint256 i = 1; i < arr.length; i++) {
            uint256 key = arr[i];
            int j = int(i) - 1;
            while (j >= 0 && arr[uint(j)] < key) {
                arr[uint(j) + 1] = arr[uint(j)];
                j--;
            }
            arr[uint(j) + 1] = key;
        }
        return arr;
    }
}