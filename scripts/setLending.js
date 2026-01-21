const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  // 🔁 CAMBIA ESTO
  const VAULT_ADDRESS = "0x15aaC5BCf14C353ee9b8E400D83dEb64B08b655E";
  const LENDING_ADDRESS = "0xfb8A8Ec430bb038c27aA12F0C3B74B75DB0E6D3A";

  const Vault = await hre.ethers.getContractFactory("SiprifiVault");
  const vault = Vault.attach(VAULT_ADDRESS);

  console.log("Setting lending address...");
  console.log("Vault:", VAULT_ADDRESS);
  console.log("Lending:", LENDING_ADDRESS);

  const tx = await vault.setLending(LENDING_ADDRESS);
  await tx.wait();

  console.log("✅ Lending connected to Vault");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
