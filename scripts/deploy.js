const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Desplegando contratos con la cuenta:", deployer.address);

  // 1. Desplegar el Motor de Riesgo (Risk Engine)
  const RiskEngine = await hre.ethers.getContractFactory("SiprifiRiskEngine");
  const riskEngine = await RiskEngine.deploy();
  await riskEngine.waitForDeployment();
  console.log("SiprifiRiskEngine desplegado en:", await riskEngine.getAddress());

  // 2. Desplegar la Fábrica de Mercados (Prediction Market)
  const PredictionMarket = await hre.ethers.getContractFactory("PredictionMarketV2");
  const market = await PredictionMarket.deploy();
  await market.waitForDeployment();
  console.log("PredictionMarketV2 desplegado en:", await market.getAddress());

  // 3. Desplegar el Vault de Colateral
  const Vault = await hre.ethers.getContractFactory("SiprifiVault");
  // Remove 'await market.getAddress()'
  const vault = await Vault.deploy(await riskEngine.getAddress());
  await vault.waitForDeployment();
  console.log("SiprifiVault desplegado en:", await vault.getAddress());

  // 4. Configuración Crítica: Autorizar al Vault en el Mercado
  await market.setVault(await vault.getAddress());
  console.log("Vault autorizado en el Mercado.");

  // 5. Desplegar el sistema de Préstamos (Lending)
  const Lending = await hre.ethers.getContractFactory("SiprifiLending");
  const lending = await Lending.deploy(await vault.getAddress());
  await lending.waitForDeployment();
  console.log("SiprifiLending desplegado en:", await lending.getAddress());

  console.log("\n--- Despliegue Completo ---");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});