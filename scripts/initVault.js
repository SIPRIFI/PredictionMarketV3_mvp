// scripts/initVault.js
async function main() {
  const [deployer] = await ethers.getSigners()

  const vault = await ethers.getContractAt(
    "SiprifiVault",
    process.env.VAULT_ADDRESS
  )

  const TOKENS = [
    "0xNO_TOKEN_1",
    "0xNO_TOKEN_2",
  ]

  for (const token of TOKENS) {
    const cfg = await vault.assetConfig(token)
    if (!cfg.enabled) {
      const tx = await vault.addAsset(token, 7500, 0)
      await tx.wait()
      console.log("✔ Asset añadido:", token)
    }
  }
}

main()
