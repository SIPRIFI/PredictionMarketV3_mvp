const hre = require("hardhat");

async function main() {
  console.log("\n🚀 Deploying Siprifi Finance MVP v3.0...\n");

  // ===== 1. DEPLOY SIPRIFI STUB =====
  console.log("📦 Deploying SiprifiStub...");
  const SiprifiStub = await hre.ethers.getContractFactory("SiprifiStub");
  const siprifiStub = await SiprifiStub.deploy();
  await siprifiStub.waitForDeployment();
  
  const siprifiAddress = await siprifiStub.getAddress();
  console.log(`✅ SiprifiStub: ${siprifiAddress}`);

  // ===== 2. DEPLOY PREDICTION MARKET V3 =====
  console.log("\n🏪 Deploying PredictionMarket_V3...");
  const PredictionMarketV3 = await hre.ethers.getContractFactory("PredictionMarket_V3");
  const predictionMarket = await PredictionMarketV3.deploy(siprifiAddress);
  await predictionMarket.waitForDeployment();
  
  const marketAddress = await predictionMarket.getAddress();
  console.log(`✅ PredictionMarket_V3: ${marketAddress}`);

  // ===== 3. SAVE ADDRESSES =====
  const addresses = {
    siprifiStub: siprifiAddress,
    predictionMarketV3: marketAddress,
    deployedAt: new Date().toISOString()
  };
  
  const fs = require('fs');
  fs.writeFileSync('./deployed-addresses.json', JSON.stringify(addresses, null, 2));
  
  console.log("\n📋 Contract Addresses:");
  console.log("════════════════════════════════");
  console.log(`SiprifiStub:         ${siprifiAddress}`);
  console.log(`PredictionMarket_V3: ${marketAddress}`);
  console.log(`\n💾 Addresses saved to deployed-addresses.json`);
  console.log("\n✅ DEPLOYMENT COMPLETE!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });
