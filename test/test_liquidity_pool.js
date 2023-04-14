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
        debankInstance = await DeBank.deployed();
        rngInstance = await RNG.deployed();
    });

    console.log("Testing Liquidity Pool contract");

    // Test Case 1
    // Register user
    it('Registers Users', async() => {
        let user1 = await debankInstance.register('Adam', {from: accounts[1], value:10000000000000000});
        let user2 = await debankInstance.register('Ben', {from: accounts[2], value:10000000000000000});
        let user3 = await debankInstance.register('Chad', {from: accounts[3], value:10000000000000000});
        let user4 = await debankInstance.register('Dion', {from: accounts[4], value:10000000000000000});
        let user5 = await debankInstance.register('Emily', {from: accounts[5], value:10000000000000000});
        let user6 = await debankInstance.register('Farhan', {from: accounts[6], value:10000000000000000});
        let user7 = await debankInstance.register('Graham', {from: accounts[7], value:10000000000000000});
        let user8 = await debankInstance.register('Henry', {from: accounts[8], value:10000000000000000});
        let user9 = await debankInstance.register('Inu', {from: accounts[9], value:10000000000000000});
        truffleAssert.eventEmitted(user1,'registerUser');
    });

    // Test Case 2
    // Test the creation of the Liquidity Pool
    it('Create New Liquidity Pool', async() => {

        // account[0] initialize new cro pool
        let pool_Cro = await liquidityPoolInstance.addNewPool("Cro", 5, {from: accounts[0]});
        let getCroToken = await croInstance.getToken(10000, {from:accounts[0]});
        let sendToCroPool = await liquidityPoolInstance.depositToken(0, 10000, {from:accounts[0]});
        truffleAssert.eventEmitted(pool_Cro, 'NewLiquidityPoolAdded');
    });

    // Test Case 3
    // Test the creation of the Liquidity Pool by non Liquidity Pool contract owner, an error is returned
    it("Create New Liquidity Pool (Alternative: Incorrect Liquidity Pool Owner)", async () => {
        
        // account[1] initialize new cro pool
        await truffleAssert.fails(liquidityPoolInstance.addNewPool("Cro", {from: accounts[1]}));
    });

    // Test Case 4
    // Test the creation of multiple Liquidity Pools
    it('Add Multiple Liquidity Pools', async() => {

        // account[0] initialize new Shib pool
        let pool_Shib = await liquidityPoolInstance.addNewPool("Shib", 10, {from: accounts[0]});
        let getShibToken = await shibInstance.getToken(10000, {from:accounts[0]});
        let sendToShibPool = await liquidityPoolInstance.depositToken(1, 10000, {from:accounts[0]});
        truffleAssert.eventEmitted(pool_Shib, 'NewLiquidityPoolAdded');
        
        let pool_Uni = await liquidityPoolInstance.addNewPool("Uni", 15, {from: accounts[0]});
        let getUniToken = await uniInstance.getToken(2000, {from:accounts[0]});
        let sendToUniPool = await liquidityPoolInstance.depositToken(2, 2000, {from:accounts[0]});
        truffleAssert.eventEmitted(pool_Uni, 'NewLiquidityPoolAdded');
        
    });

    // Test Case 5
    // Check the interest rate for lending to pool
    it('Check Available Currency Pool', async() => {
        let allCurrencyPools = await liquidityPoolInstance.getAllCurrency();
        assert.strictEqual(allCurrencyPools, "Cro, Shib, Uni", "Incorrect Available Currency Pool!");
    })

    // Test Case 6
    // Check the interest rate for lending to pool
    it('Check Interest Rate for Lending', async() => {
        
        // Simulate API calling and Set Cro interest rate as 5%
        await rngInstance.setRandomNumber(5);
        // Set Cro interest rate as 5% by calling simulated numder set in API
        await liquidityPoolInstance.setLenderInterestRate(0);
        // get lender interest rate for Cro 
        let lenderInerestRate = await liquidityPoolInstance.getLenderInterestRate(0);
        assert.strictEqual(lenderInerestRate.toNumber(), 5, "Incorrect Interest Rate for Lending!");

    });

    // Test Case 7
    // Check the interest rate for lending to pool, but invalid currency type
    it('Check Interest Rate for Lending (Alternative: Invalid Currency)', async() => {
        // request interest rate for invalid currency type
        await truffleAssert.reverts(liquidityPoolInstance.getLenderInterestRate(8), "The Currency is not supported yet!");
        
    });

    // Test Case 8
    // Check Transaction Fee for Different currency
    it('Lender Checks Transaction Fees', async() => {
        let getCroTransactionFees = await liquidityPoolInstance.getTransactionFee(0);
        let getShibTransactionFees = await liquidityPoolInstance.getTransactionFee(1);
        let getUniTransactionFees = await liquidityPoolInstance.getTransactionFee(2);

        assert.strictEqual(getCroTransactionFees.toNumber(), 5, "Incorrect Cro Transaction Fees");
        assert.strictEqual(getShibTransactionFees.toNumber(), 10, "Incorrect Shib Transaction Fees");
        assert.strictEqual(getUniTransactionFees.toNumber(), 15, "Incorrect Uni Transaction Fees");        
    });

    // Test Case 9
    // Check Transaction Fee for Different currency (Alternative: Invalid Currency)
    it("Lender Checks Transaction Fees (Alternative: Invalid Currency)", async() => {
        await truffleAssert.reverts(liquidityPoolInstance.getTransactionFee(3), "The Currency is not supported yet!");      
    });

    // Test Case 10
    // Check if unregistered user is able to deposit tokens into Liquidity Pool
    it("Lender Deposits Amount into Liquidity Pool (Alternative: Unregistered User)", async () => {
        await truffleAssert.fails(liquidityPoolInstance.deposit(0, 50, 1677628800, {from: accounts[0]}));
    });
    
    // Test Case 11
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

    // Test Case 12
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

    // Test Case 13
    // Lend currency with insufficient amount
    it('Lender Deposits Amount into Liquidity Pool (Alternative: Insufficient Token Amount)', async() => {

        let getCroToken = await croInstance.getToken(15, {from:accounts[2]})

        let checkCroToken = await croInstance.checkBalance(accounts[2]);

        assert.strictEqual(checkCroToken.toNumber(), 15, "Get Token Failed");

        await truffleAssert.reverts(liquidityPoolInstance.deposit(0, 0, 1677628800, {from: accounts[2]}), "Deposit amount must be greater than 0");
        
    });

    // Test Case 14
    // User Check Balance
    it('Lender Checks Balance', async() => {

        let getCroBalance = await liquidityPoolInstance.getBalance(accounts[1], 0, {from: accounts[1]});

        assert.strictEqual(getCroBalance.toNumber(), 45, "Incorrect Leftover Token Balance");        
    });

    // Test Case 15
    // User Check Balance (Alternative: Cannot Check Other User's Balance)
    it("Lender Checks Balance (Alternative: Cannot Check Other User's Balance)", async() => {
        await truffleAssert.reverts(liquidityPoolInstance.getBalance(accounts[1], 0, {from: accounts[2]}), "You are not authorised to access the balance");      
    });

    // Test Case 16
    // User Check Balance (Alternative: Invalid Currency)
    it("Lender Checks Balance (Alternative: Invalid Currency)", async() => {
        await truffleAssert.reverts(liquidityPoolInstance.getBalance(accounts[1], 4, {from: accounts[1]}), "The Currency is not supported yet!");      
    });

    // Test Case 17
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

        // let interestRate = await liquidityPoolInstance.getLenderInterestRate(1);

        // Calculate/compound interest at Time: 30 April 2023 00:00:00
        // Account[3] deposited 510 token, charged 10 token transaction fee: (510 - 10) * 2 mo. * 0.05 = 50 token
        // Account[3] deposited 1010 token: (1010 - 10) * 1 mo. * 0.05 = 50 token
        // total deposits + interest as of 30 April 2023 00:00:00: 1500 + 100 = 1600 token
        await liquidityPoolInstance.calculateInterest(1682812800);
        let balance = await liquidityPoolInstance.getBalance(accounts[3], 1);
        assert.strictEqual(balance.toNumber(), 1600, "Get Token Failed");
    });

    // Test Case 18
    // Withdraw currency with correct interest added
    it('Lender Withdraws Amount from Liquidity Pool (With correct interest added)', async() => {

        // Get 1515 Uni tokens
        let getUniToken = await uniInstance.getToken(1515, {from:accounts[4]});

        // Deposit 1515 Uni tokens at Time: 1 March 2023 00:00:00
        let lendToUni = await liquidityPoolInstance.deposit(2, 1515, 1677628800, {from: accounts[4]});

        // 1500 Uni tokens after 15 tokens were deducted as transaction fees
        let balance = await liquidityPoolInstance.getBalance(accounts[4], 2);
        assert.strictEqual(balance.toNumber(), 1500, "Get Token Failed");

        // Set Uni interest rate as 5%
        await rngInstance.setRandomNumber(5);
        await liquidityPoolInstance.setLenderInterestRate(2);
        
        // let interestRate = await liquidityPoolInstance.getLenderInterestRate(2);
        
        // Calculate/compound interest at Time: 30 April 2023 00:00:00
        // Account[4] deposited 1515 token, charged 15 token transaction fee: (1515 - 15) * 2 mo. * 0.05 = 150 token
        // total deposits + interest as of 30 April 2023 00:00:00: 1500 + 150 = 1650 token
        await liquidityPoolInstance.calculateInterest(1682812800);

        // Account[4] withdraws all Uni Tokens
        let withdrawUni = await liquidityPoolInstance.withdraw(1650, 2, {from: accounts[4]});

        truffleAssert.eventEmitted(withdrawUni, "WithdrawalMade");

        // verify that Account[4]'s Uni Token Balance is back to 0
        let ownedUniToken = await liquidityPoolInstance.getBalance(accounts[4], 2);
        assert.strictEqual(ownedUniToken.toNumber(), 0, "Incorrect Token Balance");
        
    });

    // Test Case 19
    // Check the interest rate for borrowing from pool
    it('Check Interest Rate for Borrowing', async() => {
        
        // Simulate API calling and Set Shib interest rate as 5%
        await rngInstance.setRandomNumber(12);
        // Set Shib interest rate as 12% by calling simulated numder set in API
        await liquidityPoolInstance.setBorrowerInterestRate(1);
        // get borrower interest rate for Shib 
        let borrowerInerestRate = await liquidityPoolInstance.getBorrowerInterestRate(1);
        assert.strictEqual(borrowerInerestRate.toNumber(), 12, "Incorrect Interest Rate for Borrowing!");

    });

    // Test Case 20
    // Check the interest rate for borrowing from pool, but invalid currency type
    it('Check Interest Rate for Borrowing (Alternative: Invalid Currency)', async() => {
        // request interest rate for invalid currency type
        await truffleAssert.reverts(liquidityPoolInstance.getBorrowerInterestRate(4), "The Currency is not supported yet!");
        
    });

    // Test Case 21
    // Deposit collateral
    it('Deposit Collateral for Loan from Liquidity Pool', async() => {
        let getCroToken = await croInstance.getToken(150, {from:accounts[4]});
        let depositCollateral = await liquidityPoolInstance.depositCollateral(0,1,150, {from:accounts[4]});

        // let collateralAmount = await liquidityPoolInstance.getCollateralAmounts(0, {from:accounts[4]});
        let collateralAmount = await liquidityPoolInstance.getCollateralAmountForCurrency(accounts[4], 1);

        // let getCroToken = await croInstance.getToken(15, {from:accounts[1]})
        assert.strictEqual(collateralAmount.toNumber(), 150, "Get Token Failed");
    });

    // Test Case 22
    // Deposit collateral with insufficient amount
    it('Deposit Collateral for Loan from Liquidity Pool (Alternative: Insufficient Token Amount)', async() => {
        await truffleAssert.reverts(liquidityPoolInstance.depositCollateral(0,1,150, {from:accounts[4]}), "You dont have enough token to deposit");
    });

    // Test Case 23
    // Borrow money with collateral from liquidity pool
    it('Borrower Loan Amount from Liquidity Pool', async() => {
        await debankInstance.initializeCro(1,1);
        await debankInstance.initializeShib(1,1);
        await debankInstance.initializeUni(1,1);

        let borrowLoan = await liquidityPoolInstance.borrow(100, 1, 1677628800, {from:accounts[4]});

        truffleAssert.eventEmitted(borrowLoan, "LoanBorrowed");

        let loanAmount = await liquidityPoolInstance.getLoanBalance(accounts[4], 1);

        assert.strictEqual(loanAmount.toNumber(), 100, "Get Token Failed");
    });

    // Test Case 24
    // Borrow money with insufficient loan amount
    it('Borrower Loan Amount from Liquidity Pool (Alternative: Insufficint Loan Amount)', async() => {
        await truffleAssert.reverts(liquidityPoolInstance.borrow(0, 1, 1677628800, {from:accounts[4]}), "Loan amount must be greater than 0");
    });

    // Test Case 25
    // Borrow money with insufficient collateral
    it('Borrower Loan Amount from Liquidity Pool (Alternative: Insufficint Collateral)', async() => {
        await truffleAssert.reverts(liquidityPoolInstance.borrow(150, 1, 1677628800, {from:accounts[4]}), "Insufficient collateral to borrow");
    });

    // Test Case 26
    // Calculate interest for borrower
    it('Borrower Interest Compounded', async() => {

        // Deposit 120 Cro token as Collateral for Uni tokens
        await croInstance.getToken(120, {from:accounts[5]});
        await liquidityPoolInstance.depositCollateral(0,2,120, {from:accounts[5]});

        let collateralAmount = await liquidityPoolInstance.getCollateralAmountForCurrency(accounts[5], 2);

        assert.strictEqual(collateralAmount.toNumber(), 120, "Get Token Failed");

        // Borrow 80 Uni tokens at Time: 1 March 2023 00:00:00
        let borrowLoan = await liquidityPoolInstance.borrow(80, 2, 1677628800, {from:accounts[5]});

        truffleAssert.eventEmitted(borrowLoan, "LoanBorrowed");

        let loanAmount = await liquidityPoolInstance.getLoanBalance(accounts[5], 2);

        // Check if loan accounted for correctly
        assert.strictEqual(loanAmount.toNumber(), 80, "Get Token Failed");

        // Set Uni interest rate as 5%
        await rngInstance.setRandomNumber(5);
        await liquidityPoolInstance.setBorrowerInterestRate(0);
        await liquidityPoolInstance.setBorrowerInterestRate(1);
        await liquidityPoolInstance.setBorrowerInterestRate(2);

        // Calculate/compound interest at Time: 30 April 2023 00:00:00
        // Account[5] borrowed 80 token: 80 * 2 mo. * 0.05 = 8 token
        // total loan + interest as of 30 April 2023 00:00:00: 80 + 8 = 88 token
        await liquidityPoolInstance.calculateLoanInterestForBorrower(1682812800,accounts[5]);
        let balance = await liquidityPoolInstance.getLoanBalance(accounts[5], 2);
        assert.strictEqual(balance.toNumber(), 88, "Get Token Failed");
    });

    // Test Case 27
    // Return loan amount borrowed back to liquidity pool
    it('Borrower Returns Withdrawn Loan Amount Back to Liquidity Pool', async() => {
        let returnLoan = await liquidityPoolInstance.returnLoan(100, 1, {from:accounts[4]});

        truffleAssert.eventEmitted(returnLoan, "LoanReturned");

        let loanAmount = await liquidityPoolInstance.getLoanBalance(accounts[4], 1);

        assert.strictEqual(loanAmount.toNumber(), 0, "Get Token Failed");
        //check if collateral is returned to the user
        let returnCollateralAmount = await croInstance.checkBalance(accounts[4]);

        assert.strictEqual(returnCollateralAmount.toNumber(), 150, "Collateral Returned Failed");
    });
    
    // Test Case 28
    // Margin call warning: collateral < x1.2 (Triggered by new loan)
    it('Margin Call Warning: Collateral Less Than 120%', async() => {
        await debankInstance.initializeShib(1,1);
        await debankInstance.initializeCro(1,1);

        // Deposit 15 Shib token as Collateral for Cro tokens
        await shibInstance.getToken(15, {from:accounts[6]});
        await liquidityPoolInstance.depositCollateral(1,0,15, {from:accounts[6]});

        let collateralAmount = await liquidityPoolInstance.getCollateralAmountForCurrency(accounts[6], 0);

        assert.strictEqual(collateralAmount.toNumber(), 15, "Get Token Failed");

        // Borrow 10 Cro tokens at Time: 1 March 2023 00:00:00
        let borrowLoan = await liquidityPoolInstance.borrow(10, 0, 1677628800, {from:accounts[6]});

        truffleAssert.eventEmitted(borrowLoan, "LoanBorrowed");

        let loanAmount = await liquidityPoolInstance.getLoanBalance(accounts[6], 0);

        // check if loan accounted for correctly
        assert.strictEqual(loanAmount.toNumber(), 10, "Get Token Failed");

        await debankInstance.initializeCro(5,4);

        let marginCall = await liquidityPoolInstance.marginCall(accounts[6], 0, 10);
        
        // Ratio of Collateral : Loan = 15*1 : 10*1.2 <= 1.2
        truffleAssert.eventEmitted(marginCall, "MarginCallWarningSent");

        let collateralAmount2 = await liquidityPoolInstance.getCollateralAmountForCurrency(accounts[6], 0);

        // total Collateral Amount for Uni tokens should still be 15 since it has not been liquidated yet
        assert.strictEqual(collateralAmount2.toNumber(), 15, "Get Token Failed");
    });

    // Test Case 29
    // Margin call warning: collateral < x1.2 (Triggered by calculate interest)
    it('Margin Call Warning: Collateral Less Than 120% (Triggered by Calculate Interest)', async() => {
        await debankInstance.initializeShib(1,1);
        await debankInstance.initializeCro(1,1);

        // Deposit 15 Shib token as Collateral for Cro tokens
        await shibInstance.getToken(15, {from:accounts[7]});
        await liquidityPoolInstance.depositCollateral(1,0,15, {from:accounts[7]});

        let collateralAmount = await liquidityPoolInstance.getCollateralAmountForCurrency(accounts[7], 0);

        assert.strictEqual(collateralAmount.toNumber(), 15, "Get Token Failed");

        // Borrow 10 Uni tokens at Time: 1 March 2023 00:00:00
        let borrowLoan = await liquidityPoolInstance.borrow(10, 0, 1677628800, {from:accounts[7]});

        truffleAssert.eventEmitted(borrowLoan, "LoanBorrowed");

        let loanAmount = await liquidityPoolInstance.getLoanBalance(accounts[7], 0);

        // check if loan accounted for correctly
        assert.strictEqual(loanAmount.toNumber(), 10, "Get Token Failed");

        await debankInstance.initializeCro(5,4);

        // Calculate/compound interest at Time: 30 April 2023 00:00:00
        // Account[6] borrowed 10 token: 10 * 2 mo. * 0.05 = 1 token
        // total loan + interest as of 30 April 2023 00:00:00: 10 + 1 = 11 token
        let interest = await liquidityPoolInstance.calculateLoanInterestForBorrower(1682812800, accounts[7]);
        
        // Ratio of Collateral : Loan = 15*1 : 11*1.2 < 1.2
        truffleAssert.eventEmitted(interest, "MarginCallWarningSent");

        let collateralAmount2 = await liquidityPoolInstance.getCollateralAmountForCurrency(accounts[7], 0);

        // total Collateral Amount for Uni tokens should still be 15 since it has not been liquidated yet
        assert.strictEqual(collateralAmount2.toNumber(), 15, "Get Token Failed");
    });

    // Test Case 30
    // Margin call liquidate: collateral < x1.05 (Triggered by new loan)
    it('Margin Call Liquidate: Collateral Less Than 150%', async() => {
        await debankInstance.initializeShib(1,1);
        await debankInstance.initializeCro(1,1);

        // Deposit 15 Shib token as Collateral for Cro tokens
        await shibInstance.getToken(15, {from:accounts[8]});
        await liquidityPoolInstance.depositCollateral(1,0,15, {from:accounts[8]});

        let collateralAmount = await liquidityPoolInstance.getCollateralAmountForCurrency(accounts[8], 0);

        assert.strictEqual(collateralAmount.toNumber(), 15, "Get Token Failed");

        // Borrow 10 Cro tokens at Time: 1 March 2023 00:00:00
        let borrowLoan = await liquidityPoolInstance.borrow(10, 0, 1677628800, {from:accounts[8]});

        truffleAssert.eventEmitted(borrowLoan, "LoanBorrowed");

        let loanAmount = await liquidityPoolInstance.getLoanBalance(accounts[8], 0);

        // check if loan accounted for correctly
        assert.strictEqual(loanAmount.toNumber(), 10, "Get Token Failed");

        await debankInstance.initializeCro(8,4);

        let marginCall = await liquidityPoolInstance.marginCall(accounts[8], 0, 10);
        
        // Ratio of Collateral : Loan = 15*1 : 10*2 <= 1.05
        truffleAssert.eventEmitted(marginCall, "CollateralLiquidated");

        let collateralAmount2 = await liquidityPoolInstance.getCollateralAmountForCurrency(accounts[8], 0);

        // total Collateral Amount for Cro tokens should be 0 since it has been liquidated
        assert.strictEqual(collateralAmount2.toNumber(), 0, "Get Token Failed");
    });

    // Test Case 31
    // Margin call liquidate: collateral < x1.05 (Triggered by calculate interest)
    it('Margin Call Liquidate: Collateral Less Than 150% (Triggered by Calculate Interest)', async() => {
        await debankInstance.initializeCro(1,1);
        await debankInstance.initializeUni(1,1);

        // Deposit 120 Cro token as Collateral for Uni tokens
        await croInstance.getToken(120, {from:accounts[9]});
        await liquidityPoolInstance.depositCollateral(0,2,120, {from:accounts[9]});

        let collateralAmount = await liquidityPoolInstance.getCollateralAmountForCurrency(accounts[9], 2);

        assert.strictEqual(collateralAmount.toNumber(), 120, "Get Token Failed");

        // Borrow 80 Uni tokens at Time: 1 March 2023 00:00:00
        let borrowLoan = await liquidityPoolInstance.borrow(80, 2, 1677628800, {from:accounts[9]});

        truffleAssert.eventEmitted(borrowLoan, "LoanBorrowed");

        let loanAmount = await liquidityPoolInstance.getLoanBalance(accounts[9], 2);

        // check if loan accounted for correctly
        assert.strictEqual(loanAmount.toNumber(), 80, "Get Token Failed");

        await debankInstance.initializeUni(8,4);

        // Calculate/compound interest at Time: 30 April 2023 00:00:00
        // Account[5] borrowed 80 token: 80 * 2 mo. * 0.05 = 8 token
        // total loan + interest as of 30 April 2023 00:00:00: 80 + 8 = 88 token
        let interest = await liquidityPoolInstance.calculateLoanInterestForBorrower(1682812800, accounts[9]);
        
        // Ratio of Collateral : Loan = 120 : 88*2 < 1.05
        truffleAssert.eventEmitted(interest, "CollateralLiquidated");

        let collateralAmount2 = await liquidityPoolInstance.getCollateralAmountForCurrency(accounts[9], 2);

        // total Collateral Amount for Uni tokens should be 0 since it has been liquidated
        assert.strictEqual(collateralAmount2.toNumber(), 0, "Get Token Failed");
    });

    
})