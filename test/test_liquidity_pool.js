const _deploy_contracts = require("../migrations/2_deploy_contracts");
const truffleAssert = require("truffle-assertions");
var assert = require("assert");

const BigNumber = require('bignumber.js'); // npm install bignumber.js
// const oneEth = new BigNumber(1000000000000000000); // 1 eth
var LiquidityPool = artifacts.require("../contracts/LiquidityPool.sol");
var DeBank = artifacts.require("../contracts/DeBank.sol");
var RNG = artifacts.require("../contracts/RNG.sol");
var Cro = artifacts.require("../contracts/Cro.sol");
var Shib = artifacts.require("../contracts/Shib.sol");
var Uni = artifacts.require("../contracts/Uni.sol");


contract ('Liquidity Pool', function(accounts){
    before( async() => {
        croInstance = await Cro.deployed();
        shibInstance = await Shib.deployed();
        uniInstance = await Uni.deployed();
        liquidityPoolInstance = await LiquidityPool.deployed();
        rngInstance = await RNG.deployed();
    });

    console.log("Testing Liquidity Pool contract");

    // Test the creation of the Liquidity Pool
    it('Create New Liquidity Pool', async() => {

        // account[0] initialize new cro pool
        let pool_Cro = await liquidityPoolInstance.addNewPool("Cro", {from: accounts[0]});

        truffleAssert.eventEmitted(pool_Cro, 'NewLiquidityPoolAdded');
    });

    // Test the creation of the Liquidity Pool by non Liquidity Pool contract owner, an error is returned
    it("Create New Liquidity Pool (Incorrect Liquidity Pool Owner)", async () => {
        
        // account[1] initialize new cro pool
        await truffleAssert.fails(
            liquidityPoolInstance.addNewPool("Cro", {from: accounts[1]}));
    });

    // Test the creation of multiple Liquidity Pools
    it('Add Multiple Liquidity Pools', async() => {

        // account[0] initialize new Shib pool
        let pool_Shib = await liquidityPoolInstance.addNewPool("Shib", {from: accounts[0]});
        truffleAssert.eventEmitted(pool_Shib, 'NewLiquidityPoolAdded');
        
        let pool_Uni = await liquidityPoolInstance.addNewPool("Uni", {from: accounts[0]});
        truffleAssert.eventEmitted(pool_Uni, 'NewLiquidityPoolAdded');
        
    });

    // Lend currency into Liquidity Pool
    it('Lender Deposits Amount into Liquidity Pool', async() => {

        let getCroToken = await croInstance.getToken(15, {from:accounts[1]})
        
        // let value = web3.utils.toWei("20000", "finney");

        // let getCroToken = await croInstance.getToken(15, {from: accounts[1], value: value});

        let checkCroToken = await croInstance.checkBalance(accounts[1]);

        assert.strictEqual(checkCroToken.toNumber(), 15, "Get Token Successful");

        let lendToCro = await liquidityPoolInstance.deposit(0, 5, 1677628800, {from: accounts[1]});

        truffleAssert.eventEmitted(lendToCro, 'DepositMade');

        let checkCroTokenAgain = await croInstance.checkBalance(accounts[1]);

        assert.strictEqual(checkCroTokenAgain.toNumber(), 10, "Get Token Successful");
        
    });

    // lend currency with insufficient amount
    it('Lender Deposits Insufficient Amount into Liquidity Pool', async() => {

        let getCroToken = await croInstance.getToken(15, {from:accounts[2]})

        let checkCroToken = await croInstance.checkBalance(accounts[2]);

        assert.strictEqual(checkCroToken.toNumber(), 15, "Get Token Successful");

        await truffleAssert.reverts(liquidityPoolInstance.deposit(0, 0, 1677628800, {from: accounts[2]}), "Deposit amount must be greater than 0");
        
    });

    // Check if interest was compounded correctly
    it('Lender Interest Compounded', async() => {

        let getShibToken = await shibInstance.getToken(1500, {from:accounts[3]});

        let getShibToken2 = await shibInstance.getToken(1500, {from:accounts[0]});
        
        // Deposit 5 Shib tokens
        let lendToShib = await liquidityPoolInstance.deposit(1, 500, 1677628800, {from: accounts[3]});

        // Deposit 10 Shib tokens
        let lendToShib2 = await liquidityPoolInstance.deposit(1, 1000, 1678838400, {from: accounts[3]});

        let deposits = await liquidityPoolInstance.getLenderDeposits(accounts[3]);

        // // // Wednesday, 1 March 2023 00:00:00
        // await liquidityPoolInstance.setDepositTime(deposits[0], new BigNumber (1677628800));

        // // // // Wednesday, 15 March 2023 00:00:00
        // await liquidityPoolInstance.setDepositTime(deposits[1], new BigNumber (1678838400));

        // Set interest rate as 5%
        await rngInstance.setRandomNumber (5);
        await liquidityPoolInstance.setLenderInterestRate(1);

        let interestRate = await liquidityPoolInstance.getLenderInterestRate(1);

        // 5% Interest Rate, Current time Saturday, 1 April 2023 00:00:00
        await liquidityPoolInstance.calculateInterest(interestRate, 1682812800);

        // Check if 
        let balance = await liquidityPoolInstance.getBalance(accounts[3], 1);

        assert.strictEqual(balance.toNumber(), 1600, "Get Token Successful");
        
    });

    // // withdraw currency with correct interest added
    // it('Lender Withdraws Amount from Liquidity Pool (With correct interest added)', async() => {

    //     let getCroToken = await croInstance.getToken(15, {from:accounts[2]})

    //     let checkCroToken = await croInstance.checkBalance(accounts[2]);

    //     assert.strictEqual(checkCroToken.toNumber(), 15, "Get Token Successful");

    //     await truffleAssert.reverts(liquidityPoolInstance.deposit(0, 0, {from: accounts[2]}), "Deposit amount must be greater than 0");
        
    // });

    // borrow money with insufficient collateral

    // deposit collateral & borrow money 

    // calculate interest for lender

    // margin call warning: collateral < x1.2

    // margin call liquidate: collateral < x1.05

})




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