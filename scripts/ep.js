const hre = require("hardhat");

async function main() {
  const VAULT = "0x7f9DB7FF4E52538Fd25c9d88e68Ed52Cf7221387";
  const NO_TOKEN = "0xEa998eac79a8211514260699fE24e8611e83e2C7";
  const USER = "TU_DIRECCION";

  const vault = await hre.ethers.getContractAt("SiprifiVault", VAULT);
  const token = await hre.ethers.getContractAt("IERC20", NO_TOKEN);

  const balance = await token.balanceOf(USER);
  console.log("Wallet balance:", balance.toString());

  await token.approve(VAULT, balance);
  await vault.depositCollateral(NO_TOKEN, balance);

  const ebp = await vault.getAccountEBP(USER);
  console.log("EBP:", ebp.toString());
}

main().catch(console.error);
