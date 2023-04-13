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

    //Add currencies to Spot On Contract
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
        let initializeCro = await DeBankInstance.initializeCro(3,2);
        truffleAssert.eventEmitted(initializeCro, "initializeCroRate");

        return DeBankInstance.getCroRate().then(croRate => {
            assert.equal(croRate, 150);
        })
    })

    //Initialize the second currency rate (ShibRate)
    it('Initialize ShibRate', async() => {
        let initializeShib = await DeBankInstance.initializeShib(3,2);
        truffleAssert.eventEmitted(initializeShib, "initializeShibRate");

        return DeBankInstance.getShibRate().then(shibRate => {
            assert.equal(shibRate, 150);
        })
    })

    //Borrower requests for loan 
    it('Borrower Requests For Loan', async() => {
        // send tokens to account...
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
            let  = await SpotOnInstance.requestLoan(100, 0, 10, 5, 360, 140, 0, {from:accounts[1]});
        } catch (e) {
            assert(e.message.includes("collateral must be at least 1.5 times of the amount"))
        }
    }); 

    //Lender takes on loan that is reqeusted by the borrower 
    it('Lender Takes On Loan', async() => {
        // send tokens to accounts[3] to be lent
        let loanTaken = await SpotOnInstance.takeOnLoan(0, {from:accounts[2]});
        truffleAssert.eventEmitted(loanTaken, "loanTaken");

        // check accounts[2] is the lender that takes up loan
        return SpotOnContractInstance.getSpotOnLender(0).then( owner => {
            assert.equal(owner, accounts[2]);
        });
    });

    //Check the repayment amount(compounded with interests rate) is correct
    it('Check Repayment Amount(Compounded with Interests Rate)', async() => {
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
        let loanOffer = await SpotOnInstance.offerLoan(100, 0, 10, 5, 360, 150, 0, {from:accounts[3]});
        truffleAssert.eventEmitted(loanOffer, "loanOffered");
        // check accounts[2] is the lender
        return SpotOnContractInstance.getSpotOnLender(1).then( owner => {
            assert.equal(owner, accounts[3]);
        });
    });

    //The Loan offered by the lender is taken on by the borrower
    it('Borrower Takes On Loan', async() => {
        let loanTaken = await SpotOnInstance.takeOnLoan(1, {from:accounts[4]});
        truffleAssert.eventEmitted(loanTaken, "loanTaken");

        // check accounts[4] is the borrower that takes up loan
        return SpotOnContractInstance.getSpotOnBorrower(1).then( owner => {
            assert.equal(owner, accounts[4]);
        });
    });
    
    //Borrower edits the loan to a lower amount such that collateral is enough to cover (more than 1.5 times)
    it('Borrower Edits Loan Amount, Collateral Enough', async() => {0
        let editAmount = await SpotOnInstance.editAmount(0, 95, {from:accounts[1]});
        truffleAssert.eventEmitted(editAmount, "loanAmountEdited");

        return SpotOnContractInstance.getAmount(0).then(amount => {
            assert.equal(amount, 95);
        });
    });

    //Borrower edits the loan to a higher amount such that it is out of the acceptable range
    it('Borrower Edits Loan Amount, Out of Acceptable Range', async() => {
        try {
            let editAmount = await SpotOnInstance.editAmount(0, 120, {from:accounts[1]});
        } catch (e) {
            // console.log(e)
            assert(e.message.includes("Out of acceptable range"))
        }
    });

    //Borrower edits the loan to a higher amount within the acceptable range, but the collateral amount is too low (lower than 1.5 times)
    it('Borrower Edits Loan Amount, Collateral not Enough', async() => {
        try {          
            let editAmount = await SpotOnInstance.editAmount(0, 105, {from:accounts[1]});
        } catch (e) {
            // console.log(e);
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

        let spotOnContractAddress = await SpotOnContractInstance.getSpotOnContractAddress(0);
        let spotOnContractBalance = await CroInstance.checkBalance(spotOnContractAddress);

        // console.log(spotOnContractAddress);
        // console.log(spotOnContractBalance);
        return assert.equal(spotOnContractBalance, 150)
    })

    //Borrower adds on to the collateral amount
    it('Borrower Adds on Collateral', async() => {
        let borrowerAddCro = await CroInstance.getToken(50, {from:accounts[1]})
        let addAmount = await SpotOnInstance.addCollateral(0, 50, {from:accounts[1]});
       
        truffleAssert.eventEmitted(addAmount, "collateralAdded");

        let spotOnContractAddress = await SpotOnContractInstance.getSpotOnContractAddress(0);
        let spotOnContractBalance = await CroInstance.checkBalance(spotOnContractAddress);

        // console.log(spotOnContractAddress);
        // console.log(spotOnContractBalance);
        return assert.equal(spotOnContractBalance, 200)
    });

    //Lender transfers Money to the borrower
    it("Lender Transfer Money", async() => {
        let editAmount = await SpotOnInstance.editAmount(0, 100, {from:accounts[1]});
        let setTransactionFee = await HelperInstance.setTransactionFee(5);

        //add Cro Balance to lender account
        let lenderaddCro = await CroInstance.getToken(105, {from:accounts[2]})
        let amount = await SpotOnContractInstance.getAmount(0);

        // lender transfers money
        let lenderTransfers = await SpotOnInstance.transferAmount(0, {from:accounts[2]});
        truffleAssert.eventEmitted(lenderTransfers, "Transferred");

        let BorrowerAddress = await SpotOnContractInstance.getSpotOnBorrower(0);
        let BorrowerBalance = await CroInstance.checkBalance(BorrowerAddress);

        // console.log(BorrowerBalance);
        return assert.equal(BorrowerBalance, 100);
    })

    //Check that the collected Transsaction Fee is collected in SpotOn Instance
    it("Check Collected Transfer Fee in SpotOn", async() => {
        let spotOnAddress = await SpotOnInstance.getOwner();
        let transactionFee = await SpotOnInstance.getTotalTransactionFee(0);

        return assert.equal(transactionFee, 5);
    })

    //Margin Call is trigered, ratio of collateral amount to amount is less than 120%, warning is given
    it("Trigger Margin Call, Ratio Less Than 120%, Warning is Given", async() => {
        let initializeCro = await DeBankInstance.initializeCro(18,10);
        let croRate = await DeBankInstance.getCroRate(); // 180%
        // console.log(croRate);
        let amount = await SpotOnContractInstance.getAmount(0); 
        let newAmount = croRate*amount/100; //18 
        // console.log(newAmount);
        let triggerMarginCall = await SpotOnInstance.triggerMarginCall(0,newAmount);

        truffleAssert.eventEmitted(triggerMarginCall, "warningCollateralLow");
    })

    //Margin Call triggered, ratio of collateral amount to amount is less than 105%, spotOnContract is liquidated
    it("Trigger Margin Call, Ratio Less Than 105%, Collateral is Liquidated", async() => {
        let initializeCro = await DeBankInstance.initializeCro(4,2);
        let croRate = await DeBankInstance.getCroRate(); // 200%
        let amount = await SpotOnContractInstance.getAmount(0);
        let newAmount = croRate*amount/100;
        let triggerMarginCall = await SpotOnInstance.triggerMarginCall(0,newAmount);

        truffleAssert.eventEmitted(triggerMarginCall, "MarginCallTriggered");
    })


})

