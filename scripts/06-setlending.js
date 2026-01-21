const hre = require("hardhat");

async function main() {
  const VAULT = "0x15aaC5BCf14C353ee9b8E400D83dEb64B08b655E";
  const LENDING = "0xfb8A8Ec430bb038c27aA12F0C3B74B75DB0E6D3A";

  const vault = await hre.ethers.getContractAt(
    "SiprifiVault",
    VAULT
  );

  const tx = await vault.setLending(LENDING);
  await tx.wait();

  console.log("✅ Lending conectado al Vault");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
