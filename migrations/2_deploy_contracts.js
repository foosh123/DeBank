const Cro = artifacts.require("Cro");
const Shib = artifacts.require("Shib");
const Uni = artifacts.require("Uni");

const DeBank = artifacts.require("DeBank");
const ERC20 = artifacts.require("ERC20");
const RNG = artifacts.require("RNG");
const LiquidityPool = artifacts.require("LiquidityPool");
const SpotOn = artifacts.require("SpotOn");
const SpotOnContract = artifacts.require("SpotOnContract");

// const DiceMarket = artifacts.require("DiceMarket");

const BigNumber = require('bignumber.js'); // npm install bignumber.js
const oneEth = new BigNumber(1000000000000000000); // 1 eth

module.exports = (deployer , network, accounts) => {
    deployer.deploy(Cro)

    .then(function() {
        return deployer.deploy(Shib);
    })
    .then(function() {
        return deployer.deploy(Uni);
    })
    .then(function() {
        return deployer.deploy(DeBank);
    })
    .then(function() {
        return deployer.deploy(RNG);
    })
    .then(function() {
        return deployer.deploy(SpotOnContract);
    })
    .then(function(){
        return deployer.deploy(SpotOn, SpotOnContract.address, Cro.address, Shib.address, Uni.address, DeBank.address);
        
    }).then(function(){
        return deployer.deploy(LiquidityPool, DeBank.address, RNG.address, Cro.address, Shib.address, Uni.address);
    });

}