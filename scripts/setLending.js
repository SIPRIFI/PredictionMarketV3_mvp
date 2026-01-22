const hre = require("hardhat");

async function main() {
  const VAULT = "0x3C6F1f584456A5f221983a213ceCfF030B3CBd74";      // EL VAULT DONDE DEPOSITASTE
  const LENDING = "0x8146741fdf807c0ADA05B13B847eFF36FD7feAd9";    // TU SiprifiLending

  const vault = await hre.ethers.getContractAt("SiprifiVault", VAULT);

  const tx = await vault.setLending(LENDING);
  await tx.wait();

  console.log("✅ Lending conectado al Vault");
}

main().catch(console.error);
