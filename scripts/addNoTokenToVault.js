const hre = require("hardhat");

async function main() {
  const VAULT = "0x3C6F1f584456A5f221983a213ceCfF030B3CBd74";     
  const NO_TOKEN = "0x68C7210B20E9b0B90D3dBc68772c6323a6ceB665";      
  const LTV = 7500;                    
  const GROUP = 0;                     

  const vault = await hre.ethers.getContractAt(
    "SiprifiVault",
    VAULT
  );

  const tx = await vault.addAsset(NO_TOKEN, LTV, GROUP);
  await tx.wait();

  console.log("✅ NO token added to Vault:", NO_TOKEN);
}

main().catch(console.error);
