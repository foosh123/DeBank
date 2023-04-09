const _deploy_contracts = require("../migrations/2_deploy_contracts");
const truffleAssert = require("truffle-assertions");
var assert = require("assert");

// const BigNumber = require('bignumber.js'); // npm install bignumber.js
// const oneEth = new BigNumber(1000000000000000000); // 1 eth


// contract ('DiceMarket', function(accounts){
//     before( async() => {
//         diceInstance = await Dice.deployed();
//         diceMarketInstance = await DiceMarket.deployed();
//     });

//     console.log("Testing Dice Market contract");

// create pool * 3

// lend currency

// lend currency with insufficient amount

// withdraw currency with correct interest added

// borrow money with insufficient collateral

// deposit collateral & borrow money 

// margin call warning: collateral < x1.2

// margin call liquidate: collateral < x1.05

// })




//1. Borrow [ok]
//  a. check if enuf collateral
//2. Return Loan []
//  a. need to return collateral
//  b. if all loan is cleared, must remove the Collateral instance from the collateralAmount array (use pop)
//3. CalculateInterest [ok]
//  a. check margin risk: warning OR liquidate
//4. DepositCollateral [ok]
//5. Liquidate []

// const _deploy_contracts = require("../migrations/2_deploy_contracts");
// const truffleAssert = require("truffle-assertions");
// const BigNumber = require('bignumber.js'); // npm install bignumber.js
// var assert = require("assert");

// const oneEth = new BigNumber(1000000000000000000); // 1 eth

// var Dice = artifacts.require("../contracts/Dice.sol");
// var DiceMarket = artifacts.require("../contracts/DiceMarket.sol");

// contract ('DiceMarket', function(accounts){
//     before( async() => {
//         diceInstance = await Dice.deployed();
//         diceMarketInstance = await DiceMarket.deployed();
//     });

//     console.log("Testing Dice Market contract");
    
//     //----------------------------Tesr case 1-----------------------------------
//     //Acc#1: Buy 1 Dice -> Dice 0
//     it('Get Dice', async() =>{

//         let makeD1 = await diceInstance.add(1,1,{from: accounts[1], value: oneEth.dividedBy(10)});

//         await assert.notStrictEqual(
//             makeD1,
//             undefined,
//             "Failed to Make Dice"
//         );

//     });

//     it('Get Dice (check correct owner)', async() =>{
//         // We can cast the return value into a BigNumber
//         const d1DiceSides = new BigNumber(await diceInstance.getDiceSides(0));
        
//         d1CorrectDiceSides = new BigNumber(1);

//         // Using the BigNumber isEqualTo
//         await assert(
//             d1DiceSides.isEqualTo(d1CorrectDiceSides),
//             "Dice#0 owner for account 1 is wrong"
//         );
//     });

//     //----------------------------Tesr case 2-----------------------------------
//     it('Get Dice (check ether supply to add function)', async() =>{
//         // Using the BigNumber isEqualTo
//         let diceValue = await diceInstance.getDiceValue(0);
//         await assert.strictEqual(
//             diceValue.toString(),
//             oneEth.dividedBy(10).toString(),
//             "Ether is not supplied to the Dice contract's add function"
//         );
//     });

//     //----------------------------Tesr case 3-----------------------------------
//     //Acc#1: Transfer Dice 0 to Market
//     it('transfer ownership of dice', async () => {

//         let t1 = await diceInstance.transfer(0, diceMarketInstance.address, {from: accounts[1]});

//     });

//     it('transfer ownership of dice (alternative)', async () => {
//         const d1Owner = await diceInstance.getOwner(0);

//         // We can check the the owner is the dice is the DiceMarket Address
//         await assert.strictEqual(
//             d1Owner,
//             diceMarketInstance.address,
//             "Dice owner not set to DiceMarket"
//         );
//     });


//     //----------------------------Tesr case 4-----------------------------------
//     it('List Dice, cannot list if(Test price < value + commision', async () => {
        
//         //list a dice for sale. Price needs to be >= value + fee
//         //function list(uint256 id, uint256 price) public {
//         // let list = await diceMarketInstance.list(0, oneEth.dividedBy(10), {from: accounts[1]});
//         await truffleAssert.fails(
//             diceMarketInstance.list(0, oneEth.dividedBy(10), {from: accounts[1]})
//         );
//     });

//     //----------------------------Tesr case 5-----------------------------------
//     it('List Dice, can list if(Test price >= value + commision)', async () => {
//         //list a dice for sale. Price needs to be >= value + fee
//         //function list(uint256 id, uint256 price) public {
//         //let list = await diceMarketInstance.list(0, 2*oneEth.dividedBy(10), {from: accounts[1]});

//         let value = await diceInstance.getDiceValue(0);
//         let comissionFee = await diceMarketInstance.comissionFee();
//         let listingPrice = value.add(comissionFee);
//         await diceMarketInstance.list(0, listingPrice, { from: accounts[1] });
        
//         let listedPrice = await diceMarketInstance.checkPrice(0);
//         // if listed, listedPrice will be non-zero
//         await assert.notStrictEqual(listedPrice.toString(), "0", "Not listed");
        
//     });

//     //----------------------------Tesr case 6-----------------------------------
//     it('Unlist Dice', async () => {
//         //function buy(uint256 id) public payable {
//         await diceMarketInstance.unlist(0, {from: accounts[1]});
        
//         let listedPrice = await diceMarketInstance.checkPrice(0);
//         // if listed, listedPrice will be non-zero
//         await assert.strictEqual(listedPrice.toString(), "0", "Unlist failed");

//     });

//     //----------------------------Tesr case 7-----------------------------------
//     //Acc#2: Purchase Dice 0
//     it('buy dice', async () => {
//         //function buy(uint256 id) public payable {
//         // let buyDice = await diceMarketInstance.buy(0, {from: accounts[2], value: 3*oneEth.dividedBy(10)});
        
//         //Make Dice 
//         let makeD2 = await diceInstance.add(1, 1, {from: accounts[1], value: oneEth.dividedBy(10)});
//         // transfer dice to dicemarket contract
//         await diceInstance.transfer(1, diceMarketInstance.address, {from: accounts[1]});

//         // list dice 1
//         value = await diceInstance.getDiceValue(1);
//         let comissionFee = await diceMarketInstance.comissionFee();
//         let listingPrice = value.add(comissionFee);
//         await diceMarketInstance.list(1, listingPrice, { from: accounts[1] });

//         // buy dice 1
//         await diceMarketInstance.buy(1, { from: accounts[2], value: 3*oneEth.dividedBy(10) });

//         const d2Owner = await diceInstance.getOwner(1);
//         await assert.strictEqual(d2Owner, accounts[2], "Dice owner not set to DiceMarket");
//     });
// })