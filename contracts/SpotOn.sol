// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0;

import "./SpotOnContract.sol";
import "./RNG.sol";
import "./Cro.sol";
import "./Shib.sol";
import "./Uni.sol";
import "./Debank.sol";

contract SpotOn {
    SpotOnContract spot_on_contract;
    Debank de_bank;
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
            Debank debankAddress
    ) public payable {
        spot_on_contract = spotOnContractAddress;
        de_bank = debankAddress;
        owner = msg.sender;
        cro = croContractAddress;
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
    uint256 public numOfLoans = 0;
    uint256 numCurrencyTypes = 0;

    modifier userOnly(uint256 id) {
        add = Debank.getUserAddress(id);
        require(add == msg.sender);
        _;
    }

    function requestLoan(
        uint256 amount, 
        uint256 currency, 
        uint256 acceptableRange, 
        uint256 interestRate, 
        uint256 loanPeriod, 
        uint256 collateral,
        uint256 collateralCurrency) public payable returns (uint256){
        
        require(collateral >= (amount * 3) / 2, "collateral must be at least 1.5 times of the amount");
        // creates new spotOnContract
        uint256 spotOnContractId = spot_on_contract.createContract(
            amount, currency, acceptableRange, interestRate, loanPeriod, collateral, collateralCurrency
        );
        
        spot_on_contract.setBorrower(spotOnContractId, msg.sender);
        emit loanRequested(spotOnContractId);
        return spotOnContractId;
    }

    function addCurrency(string memory currencyType) public {
        numCurrencyTypes++;
        currencyTypes[numCurrencyTypes] = currencyType;
        emit CurrencyAdded(numCurrencyTypes);
    }

    function editAmount(uint256 spotOnContractId, uint256 newAmount) public returns(uint256) {
        uint256 acceptableRange = spot_on_contract.getAcceptableRange(spotOnContractId);
        uint256 amount = spot_on_contract.getAmount(spotOnContractId);
        require(newAmount <= amount + acceptableRange, "Out of acceptable range");

        uint256 currencyType = spot_on_contract.getCurrencyType(spotOnContractId);
        uint256 collateralCurrency = spot_on_contract.getCollateralCurrency(spotOnContractId);
        uint256 collateralAmount = spot_on_contract.getCollateralAmount(spotOnContractId);
        uint256 ratio = de_bank.returnRatio(currencyType, newAmount, collateralCurrency, collateralAmount);
        require(ratio >= 150, "Please add on to your collateral amount");
        spot_on_contract.setAmount(spotOnContractId, newAmount);

        emit loanAmountEdited(spotOnContractId, newAmount);
        return newAmount;
    }

    function takeOnLoan(uint256 spotOnContractId) public payable {
        require(spot_on_contract.getSpotOnBorrower(spotOnContractId) == address(0) || spot_on_contract.getSpotOnLender(spotOnContractId) == address(0));

        if (spot_on_contract.getSpotOnBorrower(spotOnContractId) == address(0)) {
            spot_on_contract.setBorrower(spotOnContractId, msg.sender);
        }

        if (spot_on_contract.getSpotOnLender(spotOnContractId) == address(0)) {
            spot_on_contract.setLender(spotOnContractId, msg.sender);
        }
        //set startDate, repaymentDate
        uint256 timeNow = getTimeStamp();
        uint256 loanPeriod = spot_on_contract.getLoanPeriod(spotOnContractId);
        uint256 repaymentDate = timeNow + loanPeriod;
        spot_on_contract.setLoanDates(spotOnContractId, timeNow);

        //set repaymentAmount
        uint256 amount = spot_on_contract.getAmount(spotOnContractId);
        uint256 interestRate = spot_on_contract.getInterestRate(spotOnContractId);
        spot_on_contract.setRepaymentAmount(spotOnContractId, timeNow, repaymentDate , interestRate, amount);
        
        emit loanTaken(spotOnContractId);
    }


    function transferAmount(uint256 spotOnContractId) public {
        address lender = spot_on_contract.getSpotOnLender(spotOnContractId);
        require (msg.sender == lender , "only lender can transfer to borrower");
        address borrower = spot_on_contract.getSpotOnBorrower(spotOnContractId);
        uint256 amount = spot_on_contract.getAmount(spotOnContractId);
        uint256 choiceOfCurrency = spot_on_contract.getCurrencyType(spotOnContractId);
        if(choiceOfCurrency == 0) { //choiceOfCurrency == 0 
            // require(cro.checkBalance(address(this)) >= amount, "Insufficient tokens in pool to withdraw");
            cro.sendToken(lender,borrower, amount);
            emit Transferred(choiceOfCurrency, amount);
        } else if(choiceOfCurrency == 1) {
            // require(shib.checkBalance(address(this)) >= amount, "Insufficient tokens in pool to withdraw");
            shib.sendToken(lender, borrower, amount);
            emit Transferred(choiceOfCurrency, amount);
        } else if(choiceOfCurrency == 2) {
            // require(uni.checkBalance(address(this)) >= amount, "Insufficient tokens in pool to withdraw");
            uni.sendToken(lender, borrower, amount);
            emit Transferred(choiceOfCurrency, amount);
        } 
    }


    function triggerMarginCall (uint256 spotOnContractId, uint256 newAmount) public returns(uint256) {
        uint256 currencyType = spot_on_contract.getCurrencyType(spotOnContractId);
        address spotOnContractAddress = spot_on_contract.getSpotOnContractAddress(0);
        uint256 collateralBalance = cro.checkBalance(spotOnContractAddress);
        uint256 collateralCurrency = spot_on_contract.getCollateralCurrency(spotOnContractId);
        
        uint256 ratio = de_bank.returnRatio(currencyType, newAmount, collateralCurrency, collateralBalance);

        if (ratio <= 105) {
            liquidateCollateral(spotOnContractId);
        } else if (ratio <= 150) {
            emit warningCollateralLow("Please add on to your collateral");
        }
        return ratio;
    }

    function liquidateCollateral(uint256 spotOnContractId) public {
        address spotOnContractAddress = spot_on_contract.getSpotOnContractAddress(spotOnContractId);
        uint256 recoverCollateral = cro.checkBalance(spotOnContractAddress);
        address lender = spot_on_contract.getSpotOnLender(spotOnContractId);

        uint256 collateralCurrency = spot_on_contract.getCollateralCurrency(spotOnContractId);
        uint256 collateralAmount = spot_on_contract.getCollateralAmount(spotOnContractId);

        
        if (collateralCurrency == 0) {
            cro.sendToken(spotOnContractAddress, lender, collateralAmount);
        } else if (collateralCurrency == 1) {
            shib.sendToken(spotOnContractAddress, lender, collateralAmount);
        } else if (collateralCurrency == 2) {
            uni.sendToken(spotOnContractAddress, lender, collateralAmount);
        } 
        emit MarginCallTriggered(spotOnContractId, recoverCollateral);
    }

    function addCollateral(uint256 spotOnContractId, uint256 amount) public {
        uint256 collateralCurrency = spot_on_contract.getCollateralCurrency(spotOnContractId);
        address spotOnContractAddress = spot_on_contract.getSpotOnContractAddress(spotOnContractId);
        address borrower = spot_on_contract.getSpotOnBorrower(spotOnContractId);
        if (collateralCurrency == 0) {
            cro.sendToken(borrower, spotOnContractAddress, amount);
        } else if (collateralCurrency == 1) {
            shib.sendToken(borrower, spotOnContractAddress, amount);
        } else if (collateralCurrency == 2) {
            uni.sendToken(borrower, spotOnContractAddress, amount);
        } 
        spot_on_contract.addCollateral(spotOnContractId, amount);
        emit collateralAdded(spotOnContractId, amount);
    }

    function offerLoan(
        uint256 amount, 
        uint256 currency, 
        uint256 acceptableRange, 
        uint256 interestRate, 
        uint256 loanPeriod, 
        uint256 collateral,
        uint256 collateralCurrency) public returns (uint256){

        require(collateral >= (amount * 3) / 2, "collateral must be at least 1.5 times of the amount");
        uint256 spotOnContractId = spot_on_contract.createContract(
            amount, currency, acceptableRange, loanPeriod, interestRate, collateral, collateralCurrency
        );

        spot_on_contract.setLender(spotOnContractId, msg.sender);
        emit loanOffered(spotOnContractId);(spotOnContractId);
        return spotOnContractId;
    }


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

    
    function depositCollateral(uint256 choiceOfCurrency, uint256 amount, uint256 spotOnContractId) public isValidCurrency(choiceOfCurrency) {
        require (amount > 0, "Can't deposit 0 tokens");
        
        //checks sender is the borrower
        address borrower = spot_on_contract.getSpotOnBorrower(spotOnContractId);
        require (msg.sender == borrower, "only borrower can deposit");

        address spotOnContractAddress = spot_on_contract.getSpotOnContractAddress(spotOnContractId);

        //transfer the token
        if(choiceOfCurrency == 0) { 
            require(cro.checkBalance(msg.sender) >= amount, "Insufficient tokens in pool to withdraw");
            cro.sendToken(spotOnContractAddress, amount);
            emit collateralTransferred(choiceOfCurrency, amount);
        } 
        else if(choiceOfCurrency == 1) {
            require(shib.checkBalance(msg.sender) >= amount, "Insufficient tokens in pool to withdraw");
            shib.sendToken(spotOnContractAddress, amount);
            emit collateralTransferred(choiceOfCurrency, amount);
        } else if(choiceOfCurrency == 2) {
            require(uni.checkBalance(msg.sender) >= amount, "Insufficient tokens in pool to withdraw");
            uni.sendToken(spotOnContractAddress, amount);
            emit collateralTransferred(choiceOfCurrency, amount);
        } 
    }

    function getTimeStamp() public view returns(uint) {
        return block.timestamp;
    }

    function getCurrencyNum() public view returns(uint256) {
        return numCurrencyTypes;
    }
}