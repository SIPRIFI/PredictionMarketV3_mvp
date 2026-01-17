const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Siprifi: Flujo Económico Completo", function () {
  let riskEngine, market, vault, lending, stablecoin, owner, speculator, protector;

  beforeEach(async function () {
    // CORRECCIÓN AQUÍ: Aseguramos que los nombres coincidan con las variables de arriba
    [owner, speculator, protector] = await ethers.getSigners();

    // 1. Despliegue de toda la infraestructura
    const RiskEngine = await ethers.getContractFactory("SiprifiRiskEngine");
    riskEngine = await RiskEngine.deploy();

    const Market = await ethers.getContractFactory("PredictionMarketV2");
    market = await Market.deploy();

    const Vault = await ethers.getContractFactory("SiprifiVault");
    vault = await Vault.deploy(await market.getAddress(), await riskEngine.getAddress());

    const Lending = await ethers.getContractFactory("SiprifiLending");
    lending = await Lending.deploy(await vault.getAddress());

    const stablecoinAddr = await lending.stablecoin();
    stablecoin = await ethers.getContractAt("SiprifiStablecoin", stablecoinAddr);

    await market.setVault(await vault.getAddress());
  });

  it("Debería ejecutar el ciclo completo: Especulación -> Protección -> Préstamo", async function () {
    // --- PASO 1: Creación del Mercado ---
    const deadline = Math.floor(Date.now() / 1000) + 86400; 
    await market.connect(protector).createMarket("¿Habrá depeg en USDC?", deadline);
    
    const marketId = 1;
    const mData = await market.markets(marketId);
    const noTokenAddr = mData.noToken;
    const noToken = await ethers.getContractAt("MarketToken", noTokenAddr);

    // --- PASO 2: Entrada de Liquidez (Especulación) ---
    const betAmount = ethers.parseEther("10");
    // CORRECCIÓN AQUÍ: Usamos 'speculator' (sin la 'd')
    await market.connect(speculator).buyShares(marketId, { value: betAmount });

    const protectorNoBalance = await noToken.balanceOf(protector.address);
    expect(protectorNoBalance).to.equal(betAmount);
    console.log("\n   [✓] Protector recibió:", ethers.formatEther(protectorNoBalance), "tokens NO.");

    // --- PASO 3: Colateralización en el Vault ---
    await vault.whitelistToken(noTokenAddr, true);
    await noToken.connect(protector).approve(await vault.getAddress(), protectorNoBalance);
    await vault.connect(protector).depositCollateral(noTokenAddr, protectorNoBalance);

    const vaultBalance = await vault.collateralBalance(protector.address, noTokenAddr);
    expect(vaultBalance).to.equal(protectorNoBalance);
    console.log("   [✓] Colateral depositado en el Vault exitosamente.");

    // --- PASO 4: Préstamo (Capital Efficiency) ---
    const positionValues = [ethers.parseEther("2000")];
    const loanAmount = ethers.parseEther("100"); 
    
    // Ajustamos N a 0 para permitir préstamo con una sola posición en este test
    await riskEngine.setN(0); 

    await lending.connect(protector).borrow(loanAmount, positionValues);

    const debt = await lending.userDebt(protector.address);
    const sipBalance = await stablecoin.balanceOf(protector.address);

    expect(debt).to.equal(loanAmount);
    expect(sipBalance).to.equal(loanAmount);

    console.log("   [✓] Préstamo exitoso: Protector ahora tiene", ethers.formatEther(sipBalance), "sipUSD.");
    console.log("   [!] FLUJO COMPLETO FINALIZADO CON ÉXITO\n");
  });
});