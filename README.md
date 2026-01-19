# Siprifi Finance: Technical Function Documentation (MVP V2)

This document provides a detailed breakdown of the smart contract functions, their Solidity implementation, and their role within the Siprifi ecosystem.

---

## 1. PredictionMarketV2.sol
This contract acts as the primary issuance layer where risk is tokenized into YES and NO shares.

### `createMarket(string memory question, uint256 deadline)`
* **Solidity Logic**: 
    ```solidity
    uint256 newMarketId = ++marketCount;
    MarketToken yesToken = new MarketToken(string.concat("Siprifi YES ", idStr), "sYES", address(this));
    MarketToken noToken = new MarketToken(string.concat("Siprifi NO ", idStr), "sNO", address(this));
    markets[newMarketId] = Market({ ... });
    ```
* **Description**: Deploys two new ERC-20 contracts for every market. It initializes the market structure with a specific deadline. The contract itself becomes the "Owner" of these tokens to manage minting permissions.

### `buyShares(uint256 marketId)`
* **Solidity Logic**:
    ```solidity
    MarketToken(m.yesToken).mint(msg.sender, msg.value);
    MarketToken(m.noToken).mint(m.owner, msg.value);
    ```
* **Description**: This is the core liquidity mechanism. When a speculator sends ETH to buy "YES" shares, the contract mints an equal amount of "NO" shares to the market creator (the protection issuer). The ETH remains escrowed in the contract as collateral.

### `resolveMarket(uint256 marketId, uint8 _outcome)`
* **Solidity Logic**:
    ```solidity
    m.resolved = true;
    m.outcome = _outcome;
    m.status = MarketStatus.Occurred;
    ```
* **Description**: Sets the final result of the event (0 for NO, 1 for YES). This state change determines which token holders can eventually claim the underlying ETH.

---

## 2. SiprifiRiskEngine.sol
The mathematical core that calculates borrowing limits based on portfolio diversification.

### `calculateEBP(uint256 baseBorrowingPower, uint256[] memory groupValues)`
* **Solidity Logic**:
    ```solidity
    uint256[] memory sorted = _sortDescending(groupValues);
    for (uint256 i = 0; i < N && i < sorted.length; i++) {
        concentrationOffset += sorted[i];
    }
    return (concentrationOffset >= baseBorrowingPower) ? 0 : baseBorrowingPower - concentrationOffset;
    ```
* **Description**: Takes the total potential borrowing power and subtracts the value of the `N` largest positions. This ensures that even if the user's biggest "Protection" fails (the event happens), the protocol remains over-collateralized.

---

## 3. SiprifiVault.sol
Manages the custody of NO shares and interfaces with the Risk Engine.

### `depositCollateral(address token, uint256 amount)`
* **Solidity Logic**:
    ```solidity
    IERC20(token).transferFrom(msg.sender, address(this), amount);
    collateralBalance[msg.sender][token] += amount;
    ```
* **Description**: Transfers the user's NO shares into the Vault. These shares represent the "Insurance Policy" that will be used as collateral for a loan.

### `getAccountEBP(address user, uint256[] memory currentPositionValues)`
* **Solidity Logic**:
    ```solidity
    for (uint256 i = 0; i < currentPositionValues.length; i++) {
        totalBasePower += (currentPositionValues[i] * 50) / 100;
    }
    return riskEngine.calculateEBP(totalBasePower, currentPositionValues);
    ```
* **Description**: Calculates the "Base Power" by applying a 50% LTV to the collateral value, then calls the Risk Engine to apply the Concentration Offset.

---

## 4. SiprifiLending.sol
The credit facility that issues the protocol's native stablecoin.

### `borrow(uint256 amount, uint256[] memory positionValues)`
* **Solidity Logic**:
    ```solidity
    uint256 ebp = vault.getAccountEBP(msg.sender, positionValues);
    require(userDebt[msg.sender] + amount <= ebp, "Insolvent: Exceeds EBP");
    userDebt[msg.sender] += amount;
    stablecoin.mint(msg.sender, amount);
    ```
* **Description**: Verifies the user's Effective Borrowing Power through the Vault. If the debt is within limits, it mints `sipUSD` directly to the user's wallet.

---

---

## Aprove NO token address to the vault
1. Connects to an already deployed `SiprifiVault`
2. Calls `addAsset()` with:
   - The token address (NO or YES)
   - Its Loan-To-Value (LTV)
   - Its correlation group
3. Waits for the transaction to be mined
4. Confirms that the asset is now accepted by the Vault

Once executed successfully, users can deposit this token as collateral.

---

## addNoTokenToVault.js (manual mode - MVP 3)

```js
const hre = require("hardhat");

async function main() {
  // Address of the deployed SiprifiVault contract
  const VAULT = "0xE6695a60C5F84fa72F30aD9a2E124E659695D835";

  // Address of the Prediction Market NO token (ERC20)
  const NO_TOKEN = "0xB43cbFBD61A12e83eAe6113071683Db43233078D";

  // Loan-To-Value: 7500 = 75%
  const LTV = 7500;

  // Correlation group (YES/NO of same market should share the same group)
  const GROUP = 0;

  // Get Vault contract instance
  const vault = await hre.ethers.getContractAt(
    "SiprifiVault",
    VAULT
  );

  // Register the token as collateral
  const tx = await vault.addAsset(NO_TOKEN, LTV, GROUP);
  await tx.wait();

  console.log("✅ NO token added to Vault:", NO_TOKEN);
}

main().catch(console.error);
```

This contract acts as the primary issuance layer where risk is tokenized into YES and NO shares.

## Technical Specifications Summary

| Whitepaper Concept        | MVP Status                  |
| ------------------------- | --------------------------- |
| Outcome risk tokenization | ✅ Implemented              |
| ERC20 outcome assets      | ✅ Implemented              |
| Trustless settlement      | ✅ Implemented              |
| Capital efficiency        | ❌ Not yet                  |
| Lending                   | ❌ Future                   |
| On-chain price discovery  | ❌ Explicitly excluded      |

> This MVP validates **the atomic unit of Siprifi risk**.

---

## 11. Deployment Notes

* Target: Testnet only
* Solidity: ^0.8.24
* No audits
* No upgradeability

---

## 12. Disclaimer

This code is experimental and unaudited.

* No financial guarantees
* No oracle protections
* Use for research and prototyping only

---

**© 2026 Siprifi Finance – Internal MVP Architecture Document**
