const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Siprifi Finance MVP", function () {
  let riskEngine, market, vault, lending, owner, user;

  beforeEach(async function () {
    [owner, user] = await ethers.getSigners();

    // 1. Deploy Risk Engine
    const RiskEngine = await ethers.getContractFactory("SiprifiRiskEngine");
    riskEngine = await RiskEngine.deploy();

    // 2. Deploy Market Factory
    const Market = await ethers.getContractFactory("PredictionMarketV2");
    market = await Market.deploy();

    // 3. Deploy Vault
    const Vault = await ethers.getContractFactory("SiprifiVault");
    vault = await Vault.deploy(await market.getAddress(), await riskEngine.getAddress());

    // 4. Deploy Lending
    const Lending = await ethers.getContractFactory("SiprifiLending");
    lending = await Lending.deploy(await vault.getAddress());

    // Configuración: Autorizar al Vault en el mercado
    await market.setVault(await vault.getAddress());
  });

  it("Debería crear un mercado y emitir tokens correctamente", async function () {
    const deadline = Math.floor(Date.now() / 1000) + 3600;
    await expect(market.createMarket("¿Evento de prueba?", deadline))
      .to.emit(market, "MarketCreated");
    
    const marketData = await market.markets(1);
    expect(marketData.exists).to.equal(true);
  });

  it("Debería permitir al usuario obtener EBP basado en colateral ficticio", async function () {
    // Simulamos valores de posiciones: [1000, 500] 
    // EBP con N=1 debería ser (ValorTotal * 0.5 LTV) - PosiciónMasGrande
    // (1500 * 0.5) = 750. 750 - 1000 = 0 (porque la posición es mayor que el poder base)
    const positionValues = [ethers.parseEther("1000"), ethers.parseEther("500")];
    const ebp = await vault.getAccountEBP(user.address, positionValues);
    
    expect(ebp).to.equal(0); 
  });
});