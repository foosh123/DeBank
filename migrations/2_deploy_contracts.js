const Cro = artifacts.require("Cro");
const Shib = artifacts.require("Shib");
const Uni = artifacts.require("Uni");

const Helper = artifacts.require("Helper");
const DeBank = artifacts.require("DeBank");
const PriceConsumer = artifacts.require("PriceConsumer");
const RNG = artifacts.require("RNG");
const LiquidityPool = artifacts.require("LiquidityPool");
const SpotOn = artifacts.require("SpotOn");
const SpotOnContract = artifacts.require("SpotOnContract");

// const DiceMarket = artifacts.require("DiceMarket");

const BigNumber = require('bignumber.js'); // npm install bignumber.js
const oneEth = new BigNumber(1000000000000000000); // 1 eth

module.exports = (deployer , network, accounts) => {
    deployer.deploy(Cro);
    deployer.deploy(Shib);
    deployer.deploy(Uni);
    deployer.deploy(DeBank);
    deployer.deploy(Helper);
    deployer.deploy(RNG);

    deployer.deploy(SpotOnContract)
    .then(function(){
        return deployer.deploy(SpotOn, SpotOnContract.address, Cro.address, Shib.address, Uni.address, DeBank.address);
    }).then(function(){
        return deployer.deploy(LiquidityPool, DeBank.address, RNG.address, Cro.address, Shib.address, Uni.address, Helper.address);
    });

    // deployer.deploy(LiquidityPool);
    deployer.deploy(PriceConsumer);
}