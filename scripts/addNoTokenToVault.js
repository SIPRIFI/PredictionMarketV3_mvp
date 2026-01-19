const hre = require("hardhat");

async function main() {
  const VAULT = "0xE6695a60C5F84fa72F30aD9a2E124E659695D835";     
  const NO_TOKEN = "0xB43cbFBD61A12e83eAe6113071683Db43233078D";      
  const LTV = 7500;                    
  const GROUP = 0;                     

  const vault = await hre.ethers.getContractAt(
    "SiprifiVault",
    VAULT
  );

  const tx = await vault.addAsset(NO_TOKEN, LTV, GROUP);
  await tx.wait();

  console.log("✅ NO token añadido al Vault:", NO_TOKEN);
}

main().catch(console.error);
