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

    it('Add Currencies to SpotOn', async() => {
        //add currency to spotOn
        let currencyAdded = await SpotOnInstance.addCurrency("Cro");
        let currencyAdded2 = await SpotOnInstance.addCurrency("Shib");
        let currencyAdded3 = await SpotOnInstance.addCurrency("Uni");
        truffleAssert.eventEmitted(currencyAdded, "CurrencyAdded");
        truffleAssert.eventEmitted(currencyAdded2, "CurrencyAdded");
        truffleAssert.eventEmitted(currencyAdded3, "CurrencyAdded");

        return SpotOnInstance.getCurrencyNum().then(currencyNum => {
            assert.equal(currencyNum, 3);
        });

    })

    it('Initialize CroRate', async() => {
        let initializeCro = await DeBankInstance.initializeCro(3,2);
        truffleAssert.eventEmitted(initializeCro, "initializeCroRate");

        return DeBankInstance.getCroRate().then(croRate => {
            assert.equal(croRate, 150);
        })
    })

    it('Initialize ShibRate', async() => {
        let initializeShib = await DeBankInstance.initializeShib(3,2);
        truffleAssert.eventEmitted(initializeShib, "initializeShibRate");

        return DeBankInstance.getShibRate().then(shibRate => {
            assert.equal(shibRate, 150);
        })
    })

    it('Borrower Requests For Loan', async() => {
        // send tokens to account...
        let loanRequest = await SpotOnInstance.requestLoan(10, 0, 2, 2, 30, 15, 0, {from:accounts[1]});
        truffleAssert.eventEmitted(loanRequest, "loanRequested");
        // check accounts[1] is the borrower
        return SpotOnContractInstance.getSpotOnBorrower(0).then(owner => {
            assert.equal(owner, accounts[1]);
        });
    });

    it('Borrower requests with too little collateral', async() => {
        try {
            let  = await SpotOnInstance.requestLoan(10, 0, 2, 2, 30, 5, 0, {from:accounts[1]});
        } catch (e) {
            assert(e.message.includes("collateral must be at least 1.5 times of the amount"))
        }
    });

    it('Lender Takes On Loan', async() => {
        // send tokens to accounts[3] to be lent
        let loanTaken = await SpotOnInstance.takeOnLoan(0, {from:accounts[2]});
        truffleAssert.eventEmitted(loanTaken, "loanTaken");

        // check accounts[3] is the lender that takes up loan
        return SpotOnContractInstance.getSpotOnLender(0).then( owner => {
            assert.equal(owner, accounts[2]);
        });
    });

    it('Lender Offers Loan', async() => {
        let loanOffer = await SpotOnInstance.offerLoan(10, 0, 2, 2, 30, 15, 0, {from:accounts[3]});
        truffleAssert.eventEmitted(loanOffer, "loanOffered");
        // check accounts[2] is the lender
        return SpotOnContractInstance.getSpotOnLender(1).then( owner => {
            assert.equal(owner, accounts[3]);
        });
    });

    it('Borrower Takes On Loan', async() => {
        let loanTaken = await SpotOnInstance.takeOnLoan(1, {from:accounts[4]});
        truffleAssert.eventEmitted(loanTaken, "loanTaken");

        // check accounts[4] is the borrower that takes up loan
        return SpotOnContractInstance.getSpotOnBorrower(1).then( owner => {
            assert.equal(owner, accounts[4]);
        });
    });
    
    it('Borrower Edits Loan Amount, Collateral enough', async() => {
        let editAmount = await SpotOnInstance.editAmount(0, 9, {from:accounts[1]});
        truffleAssert.eventEmitted(editAmount, "loanAmountEdited");

        return SpotOnContractInstance.getAmount(0).then(amount => {
            assert.equal(amount, 9);
        });
    });


    it('Borrower Edits Loan Amount, Out of Acceptable Range', async() => {
        try {
            let editAmount = await SpotOnInstance.editAmount(0, 13, {from:accounts[1]});
        } catch (e) {
            // console.log(e)
            assert(e.message.includes("Out of acceptable range"))
        }
    });

    it('Borrower Edits Loan Amount, Collateral not enough', async() => {
        try {          
            // let amount = await SpotOnContractInstance.getAmount(0);
            // console.log(amount);
            // // // let amount2 = await SpotOnContractInstance.getAmount(0);
            // // // console.log(amount2);
            // let collateralAmount = await SpotOnContractInstance.getCollateralAmount(0);
            // console.log(collateralAmount);
            // let ratio = await DeBankInstance.returnRatio(0, 11, 0, collateralAmount);
            // console.log(ratio);
            let editAmount = await SpotOnInstance.editAmount(0, 11, {from:accounts[1]});
        } catch (e) {
            // console.log(e);
            assert(e.message.includes("Please add on to your collateral amount"))
        }
    });

    it('Borrower transfer collateral', async() => {
        //add Cro Balance to borrower account
        let borrowerAddCro = await CroInstance.getToken(15, {from:accounts[1]})

        // borrower transfers collateral to spotOnContract
        let collateralTransferred = await SpotOnInstance.depositCollateral(0, 15, 0, {from:accounts[1]});
        let collateralAmt = await SpotOnContractInstance.getCollateralAmount(0);
        truffleAssert.eventEmitted(collateralTransferred, "collateralTransferred");

        let spotOnContractAddress = await SpotOnContractInstance.getSpotOnContractAddress(0);
        let spotOnContractBalance = await CroInstance.checkBalance(spotOnContractAddress);

        // console.log(spotOnContractAddress);
        // console.log(spotOnContractBalance);
        return assert.equal(spotOnContractBalance, 15)
    })


    it('Borrower adds on Collateral', async() => {
        let borrowerAddCro = await CroInstance.getToken(5, {from:accounts[1]})
        let addAmount = await SpotOnInstance.addCollateral(0, 5, {from:accounts[1]});
       
        truffleAssert.eventEmitted(addAmount, "collateralAdded");

        let spotOnContractAddress = await SpotOnContractInstance.getSpotOnContractAddress(0);
        let spotOnContractBalance = await CroInstance.checkBalance(spotOnContractAddress);

        // console.log(spotOnContractAddress);
        // console.log(spotOnContractBalance);
        return assert.equal(spotOnContractBalance, 20)
    });

    it("Lender Transfer Money", async() => {
        let editAmount = await SpotOnInstance.editAmount(0, 10, {from:accounts[1]});
        let setTransactionFee = await HelperInstance.setTransactionFee(2);
        //add Cro Balance to lender account
        let lenderaddCro = await CroInstance.getToken(12, {from:accounts[2]})
        let amount = await SpotOnContractInstance.getAmount(0);
        // console.log(amount);
        // lender transfers money
        let lenderTransfers = await SpotOnInstance.transferAmount(0, {from:accounts[2]});
        truffleAssert.eventEmitted(lenderTransfers, "Transferred");

        let BorrowerAddress = await SpotOnContractInstance.getSpotOnBorrower(0);
        let BorrowerBalance = await CroInstance.checkBalance(BorrowerAddress);

        // console.log(BorrowerBalance);
        return assert.equal(BorrowerBalance, 10);
    })

    it("Check Collected Transfer Fee in SpotOn", async() => {
        let spotOnAddress = await SpotOnInstance.getOwner();
        let transactionFee = await SpotOnInstance.getTotalTransactionFee(0);

        return assert.equal(transactionFee, 2);
    })

    it("Trigger Margin Call, ratio less than 120%, warning is given", async() => {
        let initializeCro = await DeBankInstance.initializeCro(18,10);
        let croRate = await DeBankInstance.getCroRate(); // 180%
        // console.log(croRate);
        let amount = await SpotOnContractInstance.getAmount(0); 
        let newAmount = croRate*amount/100; //18 
        // console.log(newAmount);
        let triggerMarginCall = await SpotOnInstance.triggerMarginCall(0,newAmount);

        truffleAssert.eventEmitted(triggerMarginCall, "warningCollateralLow");
    })

    it("Trigger Margin Call, ratio less than 105%, collateral is liquidated", async() => {
        let initializeCro = await DeBankInstance.initializeCro(4,2);
        let croRate = await DeBankInstance.getCroRate(); // 200%
        let amount = await SpotOnContractInstance.getAmount(0);
        let newAmount = croRate*amount/100;
        let triggerMarginCall = await SpotOnInstance.triggerMarginCall(0,newAmount);

        truffleAssert.eventEmitted(triggerMarginCall, "MarginCallTriggered");
    })


})

