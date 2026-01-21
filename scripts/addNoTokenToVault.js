const hre = require("hardhat");

async function main() {
  const VAULT = "0x7f9DB7FF4E52538Fd25c9d88e68Ed52Cf7221387";     
  const NO_TOKEN = "0xEa998eac79a8211514260699fE24e8611e83e2C7";      
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
