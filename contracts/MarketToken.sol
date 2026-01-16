// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ISiprifiLending.sol";

contract MarketToken is ERC20, Ownable {
    bool public transfersEnabled = false;
    bool public collateralEnabled = true;

    bool public immutable isNoToken;
    address public immutable marketContract;
    ISiprifiLending public immutable siprifiLending;
    uint256 public immutable marketId;

    mapping(address => mapping(address => uint256)) public collateralAllowances;

    constructor(
        string memory name_,
        string memory symbol_,
        address initialOwner,
        address _marketContract,
        address _siprifiLending,
        uint256 _marketId,
        bool _isNoToken
    ) ERC20(name_, symbol_) {
        _transferOwnership(initialOwner);
        marketContract = _marketContract;
        siprifiLending = ISiprifiLending(_siprifiLending);
        marketId = _marketId;
        isNoToken = _isNoToken;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }

    function enableTransfers() external onlyOwner {
        transfersEnabled = true;
    }

    function disableCollateral() external onlyOwner {
        collateralEnabled = false;
    }

    function approveCollateral(address spender, uint256 amount) external {
        require(isNoToken, "Solo NO tokens");
        require(collateralEnabled, "Colateral deshabilitado");
        collateralAllowances[msg.sender][spender] += amount;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        // Mint o burn → permitido
        if (from == address(0) || to == address(0)) {
            super._beforeTokenTransfer(from, to, amount);
            return;
        }

        // Antes de resolución
        if (!transfersEnabled) {
            // YES token → soulbound
            if (!isNoToken) {
                revert("YES soulbound");
            }

            // NO token → solo colateral
            require(collateralEnabled, "Colateral deshabilitado");
            require(to == address(siprifiLending), "Solo Siprifi");
            require(
                collateralAllowances[from][to] >= amount,
                "Colateral no aprobado"
            );

            collateralAllowances[from][to] -= amount;
        }

        super._beforeTokenTransfer(from, to, amount);
    }
}
