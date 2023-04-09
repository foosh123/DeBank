// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0;


contract SpotOnContract {
    struct spotOnContract {
        uint256 spotOnContractId;
        uint256 currency; 
        uint256 amount;
        uint256 repaymentAmount;
        uint256 acceptableRange;
        uint256 loadPeriod;
        uint256 interestRate; //monthly interest rate
        uint256 collateral;
        uint256 collateralCurrency;
        uint256 startDate;
        address borrower;
        address lender;  
    }
    mapping(uint256 => address) spotOnContractAddress;
    uint256 public numOfContracts = 0;
    uint256 public numOfClosedContracts = 0;
    mapping(uint256 => spotOnContract) public activeSpotOnContracts; // tracks all active spotOnContracts
    mapping(uint256 => spotOnContract) public closedSpotOnContracts; //tracks all closed spotOnContracts

    function closeContract(uint256 spotOnContractId) public {
        closedSpotOnContracts[spotOnContractId] = activeSpotOnContracts[spotOnContractId];
        delete activeSpotOnContracts[spotOnContractId];
        numOfClosedContracts++;
    }

    function getSpotOnContractAddress(uint256 spotOnContractId) public view returns(address) {
        return spotOnContractAddress[spotOnContractId];
    }

    function getSpotOnLender(uint256 spotOnContractId) public view returns(address) {
        return activeSpotOnContracts[spotOnContractId].lender;
    }

    function getSpotOnBorrower(uint256 spotOnContractId) public view returns(address) {
        return activeSpotOnContracts[spotOnContractId].borrower;
    }

    function getTimeStamp() public view returns(uint) {
        return block.timestamp;
    }

    function getCurrencyType(uint256 spotOnContractId) public view returns(uint256) {
        return activeSpotOnContracts[spotOnContractId].currency;
    }

    function getCollateralAmount(uint256 spotOnContractId) public view returns(uint256) {
        return activeSpotOnContracts[spotOnContractId].collateral;
    }

    function getCollateralCurrency(uint256 spotOnContractId) public view returns(uint256) {
        return activeSpotOnContracts[spotOnContractId].collateralCurrency;
    }

    function getAmount(uint256 spotOnContractId) public view returns(uint256) {
        return activeSpotOnContracts[spotOnContractId].amount;
    }

    function getLoanPeriod(uint256 spotOnContractId) public view returns(uint256) {
        return activeSpotOnContracts[spotOnContractId].loadPeriod;
    }

    function getInterestRate(uint256 spotOnContractId) public view returns(uint256) {
        return activeSpotOnContracts[spotOnContractId].interestRate;
    }

    function getAcceptableRange(uint256 spotOnContractId) public view returns(uint256) {
        return activeSpotOnContracts[spotOnContractId].acceptableRange;
    }

    function createContract(
        uint256 amount,
        uint256 currency,
        uint256 acceptableRange,
        uint256 interestRate,
        uint256 loanPeriod,
        uint256 collateral,
        uint256 collateralCurrency
    ) public returns(uint256) {
        uint spotOnContractId = numOfContracts++;
        spotOnContract memory newSpotOnContract = spotOnContract(
            spotOnContractId,
            currency,
            amount,
            0,
            acceptableRange,
            loanPeriod,
            interestRate,
            collateral,
            collateralCurrency,
            0,
            address(0),
            address(0)
        );
        activeSpotOnContracts[spotOnContractId] = newSpotOnContract;
        spotOnContractAddress[spotOnContractId] = address(this);
        return spotOnContractId;
    }

    //function set loan start and end date
    function setLoanDates(uint256 spotOnContractId, uint256 startDate) public {
        activeSpotOnContracts[spotOnContractId].startDate = startDate;
    }

    //function set repaymentAmount
    function setRepaymentAmount(uint256 spotOnContractId, uint256 startDate, uint256 endDate, uint256 interestRate, uint256 amount) public {
        uint256 daysBetween = (endDate - startDate) / 86400; // Number of seconds in a day
        uint256 monthsBetween = daysBetween / 30; // Approximate number of months between the dates
        uint256 interestRatePerMonth = interestRate;
        uint256 totalAmountDue = amount;
        for (uint256 i = 0; i < monthsBetween; i++) {
            totalAmountDue = (amount * (10000 + interestRatePerMonth)) / 10000; // Compounding interest monthly
        }
        activeSpotOnContracts[spotOnContractId].repaymentAmount = totalAmountDue;
    }

    function setBorrower(uint256 spotOnContractId, address borrowerAddress) public {
        activeSpotOnContracts[spotOnContractId].borrower = borrowerAddress;
    }

    function setLender(uint256 spotOnContractId, address lenderAddress) public {
        activeSpotOnContracts[spotOnContractId].lender = lenderAddress;
    }

    function setAmount(uint256 spotOnContractId, uint256 newAmount) public {
        activeSpotOnContracts[spotOnContractId].amount = newAmount;
    }

    function addCollateral(uint256 spotOnContractId, uint256 collateralAmount) public {
        activeSpotOnContracts[spotOnContractId].collateral += collateralAmount;
    }

}
