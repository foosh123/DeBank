// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0;

import "./SpotOnContract.sol";
import "./RNG.sol";
import "./Cro.sol";
import "./Shib.sol";
import "./Uni.sol";
import "./DeBank.sol";

contract SpotOn {
    SpotOnContract spot_on_contract;
    DeBank de_bank;
    address owner;
    mapping(uint256 => string) currencyTypes;
    RNG r = new RNG();
    Cro cro;
    Shib shib = shib;
    Uni uni = uni;

    constructor(SpotOnContract spotOnContractAddress,
            Cro croContractAddress,
            Shib shibContractAddress,
            Uni uniContractAddress,
            DeBank debankAddress
    ) {
        spot_on_contract = spotOnContractAddress;
        de_bank = debankAddress;
        owner = msg.sender;
        cro = croContractAddress;
        shib = shibContractAddress;
        uni = uniContractAddress;
    }

    event loanRequested(uint256 spotOnContractId);
    event loanOffered(uint256 spotOnContractId);
    event loanTaken(uint256 spotOnContractId);
    event Transferred(uint256 choiceOfCurrency, uint256 amount);
    event CurrencyAdded(uint256 numOfCurrencies);
    event MarginCallTriggered(uint spotOnContractId, uint256 collateralAmount);
    event collateralTransferred(uint256 choiceOfCurrency, uint256 amount);
    event warningCollateralLow(string addCollateral);
    event loanAmountEdited(uint256 spotOnContractId, uint256 newAmount);
    event collateralAdded(uint256 spotOnContractId, uint256 amount);

    mapping(uint256 => SpotOnContract) public spotOnContracts;  // tracks all loans that have been accepted, to check loanPeriod is valid
    mapping(uint256 => uint256) public transactionFees; //tracks transaction fees in different currencies
    uint256 public numOfLoans = 0; //tracks total number of loans
    uint256 numCurrencyTypes = 0; //tracks total number of currency types


    modifier userOnly() {
        bool result = de_bank.checkUser(msg.sender);
        require(result == true);
        _;
    }

    //modifier to check if the currency is valid
    modifier isValidCurrency(uint256 currencyType) {
        bool isValid = false;
        for (uint i = 0; i < numCurrencyTypes ; i++) {
            if(currencyType == i) {
                isValid = true;
            }
        }
        require (isValid == true, "The Currency is not supported yet!");
        _;
    }

    //function to request a loan
    function requestLoan(
        uint256 amount, 
        uint256 currency, 
        uint256 acceptableRange, 
        uint256 interestRate, 
        uint256 loanPeriod, 
        uint256 collateral,
        uint256 collateralCurrency) public payable userOnly returns (uint256){
        
        //collateral amount must be at least 1.5 times of the amount
        require(collateral >= (amount * 3) / 2, "collateral must be at least 1.5 times of the amount");
        
        //create a contract with the respective params initialized
        uint256 spotOnContractId = spot_on_contract.createContract(
            amount, currency, acceptableRange, interestRate, loanPeriod, collateral, collateralCurrency
        );
        
        //set the borrower of the spotOnContract
        spot_on_contract.setBorrower(spotOnContractId, msg.sender);
        emit loanRequested(spotOnContractId);
        return spotOnContractId;
    }


    //function to offer a loan, called by the lender 
    function offerLoan(
        uint256 amount, 
        uint256 currency, 
        uint256 acceptableRange, 
        uint256 interestRate, 
        uint256 loanPeriod, 
        uint256 collateral,
        uint256 collateralCurrency) public userOnly returns (uint256){
        
        //collateral amount must be at least 1.5 times 
        require(collateral >= (amount * 3) / 2, "collateral must be at least 1.5 times of the amount");
        
        //create a contract with the respective params initialized
        uint256 spotOnContractId = spot_on_contract.createContract(
            amount, currency, acceptableRange, loanPeriod, interestRate, collateral, collateralCurrency
        );

        //set the lender of the spotOnContract
        spot_on_contract.setLender(spotOnContractId, msg.sender);
        emit loanOffered(spotOnContractId);(spotOnContractId);
        return spotOnContractId;
    }

    //function to add a currency
    function addCurrency(string memory currencyType) public {
        //increment the numberOfCurrencyType
        numCurrencyTypes++;
        currencyTypes[numCurrencyTypes] = currencyType;
        emit CurrencyAdded(numCurrencyTypes);
    }

    //function to edit amount in the spotOnContract
    function editAmount(uint256 spotOnContractId, uint256 newAmount) public userOnly returns(uint256) {
        //check that msg.sender is the borrower        
        address borrower = spot_on_contract.getSpotOnBorrower(spotOnContractId);
        require (msg.sender == borrower , "only borrower can edit amount");
        
        //check that the new amount is within the acceptable Range
        uint256 acceptableRange = spot_on_contract.getAcceptableRange(spotOnContractId);
        uint256 amount = spot_on_contract.getAmount(spotOnContractId);
        require(newAmount >= amount - acceptableRange && newAmount <= amount + acceptableRange, "Out of acceptable range");

        //getting the necessary attributes from a spotOnCont//create a contract with the respective params initialized    
        uint256 currencyType = spot_on_contract.getCurrencyType(spotOnContractId);
        uint256 collateralCurrency = spot_on_contract.getCollateralCurrency(spotOnContractId);
        uint256 collateralAmount = spot_on_contract.getCollateralAmount(spotOnContractId);

        //check that the ratio of the amount and collateral amount is more than 150%
        uint256 ratio = de_bank.returnRatio(currencyType, newAmount, collateralCurrency, collateralAmount);
        require(ratio >= 150, "Please add on to your collateral amount");
        spot_on_contract.setAmount(spotOnContractId, newAmount);

        emit loanAmountEdited(spotOnContractId, newAmount);
        return newAmount;
    }
    
    //function to takeOnLoan, can be called by either the borrower or the lender
    function takeOnLoan(uint256 spotOnContractId) public userOnly payable {
        //check that the borrower or the lender are either empty address
        require(spot_on_contract.getSpotOnBorrower(spotOnContractId) == address(0) || spot_on_contract.getSpotOnLender(spotOnContractId) == address(0));

        //set borrower if the borrower address is empty 
        if (spot_on_contract.getSpotOnBorrower(spotOnContractId) == address(0)) {
            spot_on_contract.setBorrower(spotOnContractId, msg.sender);
        }

        //set lender if the lender address is empty
        if (spot_on_contract.getSpotOnLender(spotOnContractId) == address(0)) {
            spot_on_contract.setLender(spotOnContractId, msg.sender);
        }
        
        //set startDate, repaymentDate
        uint256 timeNow = getTimeStamp();
        uint256 loanPeriod = spot_on_contract.getLoanPeriod(spotOnContractId);

        // uint256 repaymentDate = timeNow + loanPeriod;
        spot_on_contract.setLoanDates(spotOnContractId, timeNow);

        //set repaymentAmount
        uint256 amount = spot_on_contract.getAmount(spotOnContractId);
        uint256 interestRate = spot_on_contract.getInterestRate(spotOnContractId);
        spot_on_contract.setRepaymentAmount(spotOnContractId, loanPeriod , interestRate, amount);
        
        emit loanTaken(spotOnContractId);
    }

    //function to transfer amount from lender to borrower
    function transferAmount(uint256 spotOnContractId) public userOnly {

        //check that msg.sender is the lender        
        address lender = spot_on_contract.getSpotOnLender(spotOnContractId);
        require (msg.sender == lender , "only lender can transfer to borrower");

        //getting the necessary attributes from a spotOnCont//create a contract with the respective params initialized        
        address borrower = spot_on_contract.getSpotOnBorrower(spotOnContractId);
        uint256 amount = spot_on_contract.getAmount(spotOnContractId);
        uint256 choiceOfCurrency = spot_on_contract.getCurrencyType(spotOnContractId);
        uint256 transactionFee = de_bank.getTransactionFee();
        address spotOnOwnerAddress = getOwner();

        //transfer the respective amount to the borrower and spotOnOwner depending on the currency type
        if(choiceOfCurrency == 0) { 
            require(cro.checkBalance(lender) >= amount + transactionFee, "Insufficient tokens in pool to withdraw");
            cro.sendToken(lender, borrower, amount);
            cro.sendToken(lender, spotOnOwnerAddress, transactionFee);
            emit Transferred(choiceOfCurrency, amount);
        } else if(choiceOfCurrency == 1) {
            require(shib.checkBalance(lender) >= amount + transactionFee, "Insufficient tokens in pool to withdraw");
            shib.sendToken(lender, borrower, amount);
            shib.sendToken(lender,spotOnOwnerAddress, transactionFee);
            emit Transferred(choiceOfCurrency, amount);
        } else if(choiceOfCurrency == 2) {
            require(uni.checkBalance(lender) >= amount + transactionFee, "Insufficient tokens in pool to withdraw");
            uni.sendToken(lender, borrower, amount);
            uni.sendToken(lender,spotOnOwnerAddress, transactionFee);
            emit Transferred(choiceOfCurrency, amount);
        } 
        
        //add the transactionFee to the mapping which tracks the transactionFee from different choiceofCurrency
        transactionFees[choiceOfCurrency] += transactionFee;
    }

    //function to trigger margin call
    function triggerMarginCall (uint256 spotOnContractId, uint256 newAmount) public returns(uint256) {

        //getting the necessary attributes from a spotOnContract
        uint256 currencyType = spot_on_contract.getCurrencyType(spotOnContractId);
        address spotOnContractAddress = spot_on_contract.getSpotOnContractAddress(0);
        uint256 collateralBalance = cro.checkBalance(spotOnContractAddress);
        uint256 collateralCurrency = spot_on_contract.getCollateralCurrency(spotOnContractId);
        
        //calculate the ratio of the amount against the collateral amount
        uint256 ratio = de_bank.returnRatio(currencyType, newAmount, collateralCurrency, collateralBalance);

        //if ratio is less than 105%, spotOnContract is liquidated
        if (ratio <= 105) {
            liquidateCollateral(spotOnContractId);
        } 
        // if ratio is less than 120%, collateral low warning is given
        else if (ratio <= 120) {
            emit warningCollateralLow("Please add on to your collateral");
        }
        return ratio;
    }

    //function to liquite a contract when margin call happens
    function liquidateCollateral(uint256 spotOnContractId) public {

        //getting the necessary attributes from a spotOnContract
        address spotOnContractAddress = spot_on_contract.getSpotOnContractAddress(spotOnContractId);
        uint256 recoverCollateral = cro.checkBalance(spotOnContractAddress);
        address lender = spot_on_contract.getSpotOnLender(spotOnContractId);
        uint256 collateralCurrency = spot_on_contract.getCollateralCurrency(spotOnContractId);
        uint256 collateralAmount = spot_on_contract.getCollateralAmount(spotOnContractId);

        //send token depending on currency 
        if (collateralCurrency == 0) {
            cro.sendToken(spotOnContractAddress, lender, collateralAmount);
        } else if (collateralCurrency == 1) {
            shib.sendToken(spotOnContractAddress, lender, collateralAmount);
        } else if (collateralCurrency == 2) {
            uni.sendToken(spotOnContractAddress, lender, collateralAmount);
        } 
        emit MarginCallTriggered(spotOnContractId, recoverCollateral);
    }
    
    //function to add collateral to a spotOnContract
    function addCollateral(uint256 spotOnContractId, uint256 amount) public userOnly {

        //check that msg.sender is the borrower        
        address borrower = spot_on_contract.getSpotOnBorrower(spotOnContractId);
        require (msg.sender == borrower , "only borrower can add collateral");

        //get collateral currency
        uint256 collateralCurrency = spot_on_contract.getCollateralCurrency(spotOnContractId);

        //get spot on contract address
        address spotOnContractAddress = spot_on_contract.getSpotOnContractAddress(spotOnContractId);

        //add collateral to the spoton Contract
        spot_on_contract.addCollateral(spotOnContractId, amount);

        //send token depending on currency
        if (collateralCurrency == 0) {
            cro.sendToken(borrower, spotOnContractAddress, amount);
        } else if (collateralCurrency == 1) {
            shib.sendToken(borrower, spotOnContractAddress, amount);
        } else if (collateralCurrency == 2) {
            uni.sendToken(borrower, spotOnContractAddress, amount);
        } 

        emit collateralAdded(spotOnContractId, amount);
    }

    function depositCollateral(uint256 choiceOfCurrency, uint256 amount, uint256 spotOnContractId) public isValidCurrency(choiceOfCurrency) userOnly {
        //amount deposited must be more than 0
        require (amount > 0, "Can't deposit 0 tokens");
        
        //checks ,msg.sender is the borrower
        address borrower = spot_on_contract.getSpotOnBorrower(spotOnContractId);
        require (msg.sender == borrower, "only borrower can deposit");

        //get the spot on contract
        address spotOnContractAddress = spot_on_contract.getSpotOnContractAddress(spotOnContractId);

        //transfer the token
        if(choiceOfCurrency == 0) { 
            require(cro.checkBalance(borrower) >= amount, "Insufficient tokens in pool to withdraw");
            cro.sendToken(borrower, spotOnContractAddress, amount);
            emit collateralTransferred(choiceOfCurrency, amount);
        } 
        else if(choiceOfCurrency == 1) {
            require(shib.checkBalance(borrower) >= amount, "Insufficient tokens in pool to withdraw");
            shib.sendToken(borrower, spotOnContractAddress, amount);
            emit collateralTransferred(choiceOfCurrency, amount);
        } else if(choiceOfCurrency == 2) {
            require(uni.checkBalance(borrower) >= amount, "Insufficient tokens in pool to withdraw");
            uni.sendToken(borrower, spotOnContractAddress, amount);
            emit collateralTransferred(choiceOfCurrency, amount);
        } 
    }

    // -------------------------------Getters---------------------------------------//
    
    //function to get the timestamp 
    function getTimeStamp() public view returns(uint) {
        return block.timestamp;
    }

    //function to get total number of currencies
    function getCurrencyNum() public view returns(uint256) {
        return numCurrencyTypes;
    }

    //function to get total transactions fee
    function getTotalTransactionFee(uint256 currency) public view returns(uint256){
        return transactionFees[currency];
    }

    //function to get the owner of the spotOn
    function getOwner() public view returns(address){
        return owner;
    }

    
}