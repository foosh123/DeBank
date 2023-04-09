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
        let getCroToken = await croInstance.getToken(10000, {from:accounts[0]});
        let sendToCroPool = await liquidityPoolInstance.depositToken(0, 10000, {from:accounts[0]});
        truffleAssert.eventEmitted(pool_Cro, 'NewLiquidityPoolAdded');
    });

    // Test the creation of the Liquidity Pool by non Liquidity Pool contract owner, an error is returned
    it("Create New Liquidity Pool (Alternative: Incorrect Liquidity Pool Owner)", async () => {
        
        // account[1] initialize new cro pool
        await truffleAssert.fails(
            liquidityPoolInstance.addNewPool("Cro", {from: accounts[1]}));
    });

    // Test the creation of multiple Liquidity Pools
    it('Add Multiple Liquidity Pools', async() => {

        // account[0] initialize new Shib pool
        let pool_Shib = await liquidityPoolInstance.addNewPool("Shib", {from: accounts[0]});
        let getShibToken = await shibInstance.getToken(10000, {from:accounts[0]});
        let sendToShibPool = await liquidityPoolInstance.depositToken(1, 10000, {from:accounts[0]});
        truffleAssert.eventEmitted(pool_Shib, 'NewLiquidityPoolAdded');
        
        let pool_Uni = await liquidityPoolInstance.addNewPool("Uni", {from: accounts[0]});
        let getUniToken = await uniInstance.getToken(2000, {from:accounts[0]});
        let sendToUniPool = await liquidityPoolInstance.depositToken(2, 2000, {from:accounts[0]});
        truffleAssert.eventEmitted(pool_Uni, 'NewLiquidityPoolAdded');
        
    });

    // Lend currency into Liquidity Pool
    it('Lender Deposits Amount into Liquidity Pool', async() => {
        // get Cro token from Cro contract
        let getCroToken = await croInstance.getToken(100, {from:accounts[1]})
        let checkCroToken = await croInstance.checkBalance(accounts[1]);
        assert.strictEqual(checkCroToken.toNumber(), 100, "Get Token Failed");
        // deposit Shib token to Cro Pool
        let lendToCro = await liquidityPoolInstance.deposit(0, 50, 1677628800, {from: accounts[1]});
        truffleAssert.eventEmitted(lendToCro, 'DepositMade');
        
        // token balance - transaction fee: 50 - 5 = 45 tokens
        let ownedCroToken = await liquidityPoolInstance.getBalance(accounts[1], 0);
        assert.strictEqual(ownedCroToken.toNumber(), 45, "Incorrect Token Balance");

        //leftover token token in account[0]: 100 - 50 = 50 tokens
        let checkCroTokenAgain = await croInstance.checkBalance(accounts[1]);
        assert.strictEqual(checkCroTokenAgain.toNumber(), 50, "Incorrect Leftover Token Balance");
        
    });

    // Lend currency into Liquidity Pool
    it('Lender Deposits Amounts into Multiple Liquidity Pool', async() => {

        // get Shib token from Shib contract
        let getShibToken = await shibInstance.getToken(100, {from:accounts[1]})
        let checkShibToken = await shibInstance.checkBalance(accounts[1]);
        assert.strictEqual(checkShibToken.toNumber(), 100, "Get Token Failed");

        // deposit Shib token to Shib Pool
        let lendToShib = await liquidityPoolInstance.deposit(1, 100, 1677628800, {from: accounts[1]});
        truffleAssert.eventEmitted(lendToShib, 'DepositMade');

        // token balance - transaction fee: 100 - 10 = 90 tokens
        let ownedShibToken = await liquidityPoolInstance.getBalance(accounts[1], 1);
        assert.strictEqual(ownedShibToken.toNumber(), 90, "Incorrect Token Balance");


        // get Uni token from Uni contract
        let getUnibToken = await uniInstance.getToken(200, {from:accounts[1]})
        let checkUniToken = await uniInstance.checkBalance(accounts[1]);

        // deposit Uni token to Uni Pool
        assert.strictEqual(checkUniToken.toNumber(), 200, "Get Token Failed");
        let lendToUni = await liquidityPoolInstance.deposit(2, 200, 1677628800, {from: accounts[1]});
        truffleAssert.eventEmitted(lendToUni, 'DepositMade');

        // token balance - transaction fee: 200 - 15 = 185 tokens
        let ownedUniToken = await liquidityPoolInstance.getBalance(accounts[1], 2);
        assert.strictEqual(ownedUniToken.toNumber(), 185, "Incorrect Token Balance");
        
    });

    // lend currency with insufficient amount
    it('Lender Deposits Amount into Liquidity Pool (Alternative: Insufficient Token Amount)', async() => {

        let getCroToken = await croInstance.getToken(15, {from:accounts[2]})

        let checkCroToken = await croInstance.checkBalance(accounts[2]);

        assert.strictEqual(checkCroToken.toNumber(), 15, "Get Token Failed");

        await truffleAssert.reverts(liquidityPoolInstance.deposit(0, 0, 1677628800, {from: accounts[2]}), "Deposit amount must be greater than 0");
        
    });

    // Check if interest was compounded correctly
    it('Lender Interest Compounded', async() => {

        // Get 1500 Shib tokens
        let getShibToken = await shibInstance.getToken(1520, {from:accounts[3]});

        // Deposit 500 Shib tokens at Time: 1 March 2023 00:00:00
        let lendToShib = await liquidityPoolInstance.deposit(1, 510, 1677628800, {from: accounts[3]});

        // Deposit 1000 Shib tokens at Time: 15 March 2023 00:00:00
        let lendToShib2 = await liquidityPoolInstance.deposit(1, 1010, 1678838400, {from: accounts[3]});

        let deposits = await liquidityPoolInstance.getLenderDeposits(accounts[3]);

        // Set Shib interest rate as 5%
        await rngInstance.setRandomNumber(5);
        await liquidityPoolInstance.setLenderInterestRate(1);

        let interestRate = await liquidityPoolInstance.getLenderInterestRate(1);

        // Calculate/compound interest at Time: 30 April 2023 00:00:00
        // Account[3] deposited 510 token, charged 10 token transaction fee: (510 - 10) * 2 mo. * 0.05 = 50 token
        // Account[3] deposited 1010 token: (1010 - 10) * 1 mo. * 0.05 = 50 token
        // total deposits + interest as of 30 April 2023 00:00:00: 1500 + 100 = 1600 token
        await liquidityPoolInstance.calculateInterest(interestRate, 1682812800);
        let balance = await liquidityPoolInstance.getBalance(accounts[3], 1);
        assert.strictEqual(balance.toNumber(), 1600, "Get Token Failed");
    });

    // withdraw currency with correct interest added
    it('Lender Withdraws Amount from Liquidity Pool (With correct interest added)', async() => {

        // let currentBalance = await liquidityPoolInstance.getBalance(accounts[3], 1);

        // let approve = await liquidityPoolInstance.approveSpender(accounts[3], 1600, {from: liquidityPoolInstance.address});

        // let withDrawToLender = await liquidityPoolInstance.withdraw(1600, 1, {from: accounts[3]});

        // let checkCroToken = await shibInstance.checkBalance({from: accounts[3]});

        // assert.strictEqual(checkCroToken, 1600, "Withdraws Token Failed");

        // await truffleAssert.reverts(liquidityPoolInstance.deposit(0, 0, {from: accounts[2]}), "Deposit amount must be greater than 0");
        
    });

    // deposit collateral
    it('Deposit Collateral for Loan from Liquidity Pool', async() => {
        let getCroToken = await croInstance.getToken(150, {from:accounts[4]});
        let depositCollateral = await liquidityPoolInstance.depositCollateral(0,1,150, {from:accounts[4]});

        let depositAmount = await liquidityPoolInstance.getCollateralAmounts(0, {from:accounts[4]});

        // let getCroToken = await croInstance.getToken(15, {from:accounts[1]})
        assert.strictEqual(depositAmount.toNumber(), 150, "Get Token Failed");
    });

    // borrow money with collateral from liquidity pool
    it('Borrower Loan Amount from Liquidity Pool', async() => {
        
        
    });

    // borrow money with insufficient loan amount
    it('Borrower Loan Amount from Liquidity Pool (Alternative: Insufficint Loan Amount)', async() => {
        await truffleAssert.reverts(liquidityPoolInstance.borrow(0, 1, {from:accounts[4]}), "Loan amount must be greater than 0");
    });

    // borrow money with insufficient collateral
    it('Borrower Loan Amount from Liquidity Pool (Alternative: Insufficint Collateral)', async() => {
        //await truffleAssert.reverts(liquidityPoolInstance.borrow(150, 1, {from:accounts[4]}), "Insufficient collateral to borrow");
    });

    // calculate interest for borrower
    it('Borrower Interest Compounded', async() => {

    });

    // margin call warning: collateral < x1.2 (Triggered by calculate interest)
    it('Margin Call Warning: Collateral < x1.2 (Triggered by Calculate Interest)', async() => {

    });

    // margin call warning: collateral < x1.2 (Triggered by new loan)
    it('Margin Call Warning: Collateral < x1.2 (Triggered by New Loan)', async() => {

    });

    // margin call liquidate: collateral < x1.05 (Triggered by calculate interest)
    it('Margin Call Liquidate: Collateral < x1.05 (Triggered by Calculate Interest)', async() => {

    });

    // margin call liquidate: collateral < x1.05 (Triggered by new loan)
    it('Margin Call Liquidate: Collateral < x1.05 (Triggered by New Loan)', async() => {

    });
    
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