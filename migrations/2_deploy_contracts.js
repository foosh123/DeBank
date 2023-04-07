const Cro = artifacts.require("Cro");
const Shib = artifacts.require("Shib");
const Uni = artifacts.require("Uni");

const Helper = artifacts.require("Helper");
const DeBank = artifacts.require("DeBanker");
const PriceConsumer = artifacts.require("PriceConsumer");
const RNG = artifacts.require("RNG");
const LiquidityPool = artifacts.require("LiquidityPool");
const SpotOn = artifacts.require("SpotOn");
const SpotOnContract = artifacts.require("SpotOnContract");

const DiceMarket = artifacts.require("DiceMarket");

const BigNumber = require('bignumber.js'); // npm install bignumber.js
const oneEth = new BigNumber(1000000000000000000); // 1 eth

module.exports = (deployer , network, accounts) => {
    deployer.deploy(Dice)
    .then(function(){
        return deployer.deploy(DiceMarket, Dice.address, oneEth.dividedBy(10));
    })
    .then(function(){
        return deployer.deploy(DiceMarket, Dice.address, oneEth.dividedBy(10));
    });
}