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

contract('SpotOn', function(accounts) {
    before(async () => {
        SpotOnContractInstance = await SpotOnContract.deployed();
        SpotOnInstance = await SpotOn.deployed(SpotOnContractInstance.address)
        CroInstance = await Cro.deployed();
    });

    it('Borrower Requests For Loan', async() => {
        // send tokens to account...
        let loanRequest = await SpotOnInstance.requestLoan(10, 0, 2, 2, 30, 15, 0, {from:accounts[1]});
        truffleAssert.eventEmitted(loanRequest, "loanRequested");
        // check accounts[1] is the borrower
        return SpotOnContractInstance.getSpotOnBorrower(0).then( owner => {
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

    it('Borrower transfer collateral', async() => {
        //add currency to spotOn
        let addCurrency = await SpotOnInstance.addCurrency("Cro");

        //add Cro Balance to borrower account
        let borrowerAddCro = await CroInstance.getToken(15, {from:accounts[1]})

        // borrower transfers collateral to spotOnContract
        let collateralTransferred = await SpotOnInstance.depositCollateral(0, 15, 0, {from:accounts[1]});
        let collateralAmt = await SpotOnContractInstance.getCollateralAmount(0);
        truffleAssert.eventEmitted(collateralTransferred, "collateralTransferred");

        return SpotOnContractInstance.getCollateralAmount(0).then( amount => {
            assert.equal(amount, 15);
        });
    })


    // it('Borrower Edits Loan Amount', async() => {

        
    // });

    it("Lender Transfer Money", async() => {
        //add Cro Balance to lender account
        let lenderaddCro = await CroInstance.getToken(15, {from:accounts[2]})
        // lender transfers money
        let lenderTransfers = await SpotOnInstance.transferAmount(0, {from:accounts[2]});
        truffleAssert.eventEmitted(lenderTransfers, "Transferred");
    })



        // if(choiceOfCurrency == 0) { 
        //     Cro.checkBalance(spotOnContractAddress)
        //     assert.strictEqual(Cro.checkBalance(spotOnContractAddress), collateralAmt, "amount deposited is wrong");
        // } 
        // else if(choiceOfCurrency == 1) {
        //     assert.strictEqual(Shib.checkBalance(spotOnContractAddress), collateralAmt, "amount deposited is wrong");
        // } else if(choiceOfCurrency == 2) {
        //     assert.strictEqual(Uni.checkBalance(spotOnContractAddress), collateralAmt, "amount deposited is wrong");
        // } 


})

