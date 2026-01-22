// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SiprifiRiskEngine is Ownable {
    uint256 public N = 1;

    constructor() Ownable() {}

    function setN(uint256 _n) external onlyOwner {
        N = _n;
    }

    function calculateEBP(
        uint256 baseBorrowingPower,
        uint256[] memory groupValues
    ) public view returns (uint256) {

        // ✅ FIX: si hay 0 o 1 grupos, no hay riesgo de concentración
        if (groupValues.length <= 1) {
            return baseBorrowingPower;
        }

        uint256[] memory sorted = _sortDescending(groupValues);

        uint256 concentrationOffset;
        for (uint256 i = 0; i < N && i < sorted.length; i++) {
            concentrationOffset += sorted[i];
        }

        if (concentrationOffset >= baseBorrowingPower) {
            return 0;
        }

        return baseBorrowingPower - concentrationOffset;
    }

    function _sortDescending(
        uint256[] memory arr
    ) internal pure returns (uint256[] memory) {

        for (uint256 i = 1; i < arr.length; i++) {
            uint256 key = arr[i];
            uint256 j = i;

            while (j > 0 && arr[j - 1] < key) {
                arr[j] = arr[j - 1];
                j--;
            }
            arr[j] = key;
        }

        return arr;
    }
}
