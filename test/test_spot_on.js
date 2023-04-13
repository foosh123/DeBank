const _deploy_contracts = require("../migrations/2_deploy_contracts");
const truffleAssert = require("truffle-assertions");
var assert = require("assert");
const BigNumber = require('bignumber.js');

var SpotOn = artifacts.require("../contracts/SpotOn.sol");
var SpotOnContract = artifacts.require("../contracts/SpotOnContract.sol");
var DeBank = artifacts.require("../contracts/DeBank.sol");
var RNG = artifacts.require("../contracts/RNG.sol");
var Cro = artifacts.require("../contracts/Cro.sol");
var Shib = artifacts.require("../contracts/Shib.sol");
var Uni = artifacts.require("../contracts/Uni.sol");
var Helper = artifacts.require("../contracts/Helper.sol");

contract('SpotOn', function(accounts) {
    before(async () => {
        SpotOnContractInstance = await SpotOnContract.deployed();
        SpotOnInstance = await SpotOn.deployed(SpotOnContractInstance.address)
        CroInstance = await Cro.deployed();
        ShibInstance = await Shib.deployed();
        UniInstance = await Uni.deployed();
        DeBankInstance = await DeBank.deployed();
        HelperInstance = await Helper.deployed();
    });
    
    //Register all the users
    it('Registers Users', async() => {
        let user1 = await debankInstance.register('Adam', {from: accounts[1], value:10000000000000000});
        let user2 = await debankInstance.register('Ben', {from: accounts[2], value:10000000000000000});
        let user3 = await debankInstance.register('Chad', {from: accounts[3], value:10000000000000000});
        let user4 = await debankInstance.register('Dion', {from: accounts[4], value:10000000000000000});
        truffleAssert.eventEmitted(user1,'registerUser');
    });

    //Add 3 currencies to Spot On Contract
    it('Add Currencies to SpotOn', async() => {
        //add 3 different currencies
        let currencyAdded = await SpotOnInstance.addCurrency("Cro");
        let currencyAdded2 = await SpotOnInstance.addCurrency("Shib");
        let currencyAdded3 = await SpotOnInstance.addCurrency("Uni");
        truffleAssert.eventEmitted(currencyAdded, "CurrencyAdded");
        truffleAssert.eventEmitted(currencyAdded2, "CurrencyAdded");
        truffleAssert.eventEmitted(currencyAdded3, "CurrencyAdded");

        //check that the curr//create a contract with the respective params initializedes number is 3
        return SpotOnInstance.getCurrencyNum().then(currencyNum => {
            assert.equal(currencyNum, 3);
        });
    })

    //Initialize the first currency rate (croRate)
    it('Initialize CroRate', async() => {
        //Set the Rate to 150
        let initializeCro = await DeBankInstance.initializeCro(3,2);
        truffleAssert.eventEmitted(initializeCro, "initializeCroRate");

        return DeBankInstance.getCroRate().then(croRate => {
            assert.equal(croRate, 150);
        })
    })

    //Initialize the second currency rate (ShibRate)
    it('Initialize ShibRate', async() => {
        //Set Shib Rate to be 120
        let initializeShib = await DeBankInstance.initializeShib(6,5);
        truffleAssert.eventEmitted(initializeShib, "initializeShibRate");

        return DeBankInstance.getShibRate().then(shibRate => {
            assert.equal(shibRate, 120);
        })
    })

    it("Borrower Requests For Loan (Alternative: Unregistered User)", async () => {
        // 
        await truffleAssert.fails(
            SpotOnInstance.requestLoan(100, 0, 10, 5, 360, 150, 0, {from:accounts[0]}));
    });

    it('Borrower Requests For Loan', async() => {
        //request a loan with loan amount 100, currency cro, acceptable range 10, loan period 360 days, collateral 150
        let loanRequest = await SpotOnInstance.requestLoan(100, 0, 10, 5, 360, 150, 0, {from:accounts[1]});
        truffleAssert.eventEmitted(loanRequest, "loanRequested");

        // check accounts[1] is the borrower
        return SpotOnContractInstance.getSpotOnBorrower(0).then(owner => {
            assert.equal(owner, accounts[1]);
        });
    });

    //Borrower requests for loan, collateral is too little, below 1.5 ratio 
    it('Borrower Requests with Too Little Collateral', async() => {
        try {
            //request a loan with lower collatetral of 140
            let  = await SpotOnInstance.requestLoan(100, 0, 10, 5, 360, 140, 0, {from:accounts[1]});
        } catch (e) {
            assert(e.message.includes("collateral must be at least 1.5 times of the amount"))
        }
    }); 

    //Lender takes on loan that is reqeusted by the borrower 
    it('Lender Takes On Loan', async() => {
        //Lender takes on Loan
        let loanTaken = await SpotOnInstance.takeOnLoan(0, {from:accounts[2]});
        truffleAssert.eventEmitted(loanTaken, "loanTaken");

        // check accounts[2] is the lender that takes up loan
        return SpotOnContractInstance.getSpotOnLender(0).then( owner => {
            assert.equal(owner, accounts[2]);
        });
    });

    //Check the repayment amount(compounded with interests rate) is correct
    it('Check Repayment Amount(Compounded with Interests Rate)', async() => {
        //get the repaymentamount and interestRate from spotOnContract Id 0
        let repaymentAmount = await SpotOnContractInstance.getSpotOnContractRepaymentAmount(0);
        let interestRate = await SpotOnContractInstance.getInterestRate(0);

        //testing repayment amount with interest rate of 1.05 compounded monthly for a year
        //With loan amount of 10, 24 will be required to payback with interst rate
        return SpotOnContractInstance.getSpotOnContractRepaymentAmount(0).then(repaymentAmount => {
            assert.equal(repaymentAmount, 173);
        })
    })

    //Lender offers Loan on the platform
    it('Lender Offers Loan', async() => {
        //Lender offer a loan (second flow for the users)
        let loanOffer = await SpotOnInstance.offerLoan(100, 0, 10, 5, 360, 150, 0, {from:accounts[3]});
        truffleAssert.eventEmitted(loanOffer, "loanOffered");

        // check accounts[3] is the lender
        return SpotOnContractInstance.getSpotOnLender(1).then( owner => {
            assert.equal(owner, accounts[3]);
        });
    });

    //The Loan offered by the lender is taken on by the borrower
    it('Borrower Takes On Loan', async() => {
        //Borrower takes on loan offered by the lender
        let loanTaken = await SpotOnInstance.takeOnLoan(1, {from:accounts[4]});
        truffleAssert.eventEmitted(loanTaken, "loanTaken");

        // check accounts[4] is the borrower that takes up loan
        return SpotOnContractInstance.getSpotOnBorrower(1).then( owner => {
            assert.equal(owner, accounts[4]);
        });
    });
    
    //Borrower edits the loan to a lower amount such that collateral is enough to cover (more than 1.5 times)
    it('Borrower Edits Loan Amount, Collateral Enough', async() => {0
        //borrower edit amount of the loan if requested by the lender
        let editAmount = await SpotOnInstance.editAmount(0, 95, {from:accounts[1]});
        truffleAssert.eventEmitted(editAmount, "loanAmountEdited");

        return SpotOnContractInstance.getAmount(0).then(amount => {
            assert.equal(amount, 95);
        });
    });

    //Borrower edits the loan to a higher amount such that it is out of the acceptable range
    it('Borrower Edits Loan Amount, Out of Acceptable Range', async() => {
        try {
            //borrower unable to edit an amount to 120 since the acceptable range is 10, maximum is 110
            let editAmount = await SpotOnInstance.editAmount(0, 120, {from:accounts[1]});
        } catch (e) {
            assert(e.message.includes("Out of acceptable range"))
        }
    });

    //Borrower edits the loan to a higher amount within the acceptable range, but the collateral amount is too low (lower than 1.5 times)
    it('Borrower Edits Loan Amount, Collateral not Enough', async() => {
        try {          
            //borrower unable to edit amount to 105, since the collateral amount ratio will be too low
            let editAmount = await SpotOnInstance.editAmount(0, 105, {from:accounts[1]});
        } catch (e) {
            assert(e.message.includes("Please add on to your collateral amount"))
        }
    });

    //Borrower transfers the collateral amount to spotOnContracts
    it('Borrower Transfer Collateral', async() => {
        //add Cro Balance to borrower account
        let borrowerAddCro = await CroInstance.getToken(150, {from:accounts[1]})

        // borrower transfers collateral to spotOnContract
        let collateralTransferred = await SpotOnInstance.depositCollateral(0, 150, 0, {from:accounts[1]});
        let collateralAmt = await SpotOnContractInstance.getCollateralAmount(0);
        truffleAssert.eventEmitted(collateralTransferred, "collateralTransferred");

        //check the account balance of the spotOnContract in terms of the cro currency 
        let spotOnContractAddress = await SpotOnContractInstance.getSpotOnContractAddress(0);
        let spotOnContractBalance = await CroInstance.checkBalance(spotOnContractAddress);

        return assert.equal(spotOnContractBalance, 150)
    })

    //Borrower adds on to the collateral amount
    it('Borrower Adds on Collateral', async() => {
        //send tokens to the borrowre
        let borrowerAddCro = await CroInstance.getToken(50, {from:accounts[1]})

        //borrower adds on to the collateral amount
        let addAmount = await SpotOnInstance.addCollateral(0, 50, {from:accounts[1]});
       
        truffleAssert.eventEmitted(addAmount, "collateralAdded");
        
        //check the account balance of the spotOnContract in terms of the cro currency 
        let spotOnContractAddress = await SpotOnContractInstance.getSpotOnContractAddress(0);
        let spotOnContractBalance = await CroInstance.checkBalance(spotOnContractAddress);

        return assert.equal(spotOnContractBalance, 200)
    });

    //Lender transfers Money to the borrower
    it("Lender Transfer Money", async() => {
        //Re-initialize the amount of the contract
        let editAmount = await SpotOnInstance.editAmount(0, 100, {from:accounts[1]});

        // set the transaction fee to be 5
        let setTransactionFee = await HelperInstance.setTransactionFee(5);

        //add Cro Balance to lender account
        let lenderaddCro = await CroInstance.getToken(105, {from:accounts[2]})
        let amount = await SpotOnContractInstance.getAmount(0);

        // lender transfers money
        let lenderTransfers = await SpotOnInstance.transferAmount(0, {from:accounts[2]});
        truffleAssert.eventEmitted(lenderTransfers, "Transferred");

        //check the account balance of the borrower in terms of the cro currency 
        let BorrowerAddress = await SpotOnContractInstance.getSpotOnBorrower(0);
        let BorrowerBalance = await CroInstance.checkBalance(BorrowerAddress);

        return assert.equal(BorrowerBalance, 100);
    })

    //Check that the collected Transsaction Fee is collected in SpotOn Instance
    it("Check Collected Transfer Fee in SpotOn", async() => {
        //check the account balance of the spotOn in terms of the cro currency, it should match with the transaction fee
        let spotOnAddress = await SpotOnInstance.getOwner();
        let transactionFee = await SpotOnInstance.getTotalTransactionFee(0);

        return assert.equal(transactionFee, 5);
    })

    //Margin Call is trigered, ratio of collateral amount to amount is less than 120%, warning is given
    it("Trigger Margin Call, Ratio Less Than 120%, Warning is Given", async() => {
        // initialize the rate of Cro
        let initializeCro = await DeBankInstance.initializeCro(18,10);
        let croRate = await DeBankInstance.getCroRate(); // croRate is 180%   
        
        //get the amount and the new amount for margin call
        let amount = await SpotOnContractInstance.getAmount(0); 
        let newAmount = croRate*amount/100; //18 

        //triggers the margin call, warning is given to the borrower to add on collateral amount
        let triggerMarginCall = await SpotOnInstance.triggerMarginCall(0,newAmount);

        truffleAssert.eventEmitted(triggerMarginCall, "warningCollateralLow");
    })

    //Margin Call triggered, ratio of collateral amount to amount is less than 105%, spotOnContract is liquidated
    it("Trigger Margin Call, Ratio Less Than 105%, Collateral is Liquidated", async() => {
        //Re-initialize the crorate such that the ratio is less than 105%
        let initializeCro = await DeBankInstance.initializeCro(4,2);
        let croRate = await DeBankInstance.getCroRate(); //croRate is 200%
        let amount = await SpotOnContractInstance.getAmount(0);
        let newAmount = croRate*amount/100;

        //triggers the margin call and spotOnContract is liquidated, collateral amount is transffered to the lender
        let triggerMarginCall = await SpotOnInstance.triggerMarginCall(0,newAmount);

        truffleAssert.eventEmitted(triggerMarginCall, "MarginCallTriggered");
    })


})

