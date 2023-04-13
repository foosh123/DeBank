// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0;

contract SpotOnContract {
    struct spotOnContract {
        uint256 spotOnContractId;
        uint256 currency; 
        uint256 amount;
        uint256 repaymentAmount;
        uint256 acceptableRange;
        uint256 loadPeriod; //loan period in days
        uint256 interestRate; //monthly interest rate in percentage
        uint256 collateral; 
        uint256 collateralCurrency;
        uint256 startDate;
        address borrower;
        address lender;  
    }
    mapping(uint256 => address) spotOnContractAddress;
    uint256 public numOfContracts = 0; //tracks total number of contracts
    uint256 public numOfClosedContracts = 0; //tracks number of closed contracts
    mapping(uint256 => spotOnContract) public activeSpotOnContracts; // tracks all active spotOnContracts
    mapping(uint256 => spotOnContract) public closedSpotOnContracts; //tracks all closed spotOnContracts

    //function to close a completed contract
    function closeContract(uint256 spotOnContractId) public {
        closedSpotOnContracts[spotOnContractId] = activeSpotOnContracts[spotOnContractId];
        delete activeSpotOnContracts[spotOnContractId];
        numOfClosedContracts++;
    }

    //create a new spotOnContract
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

        //initialize the contract with contractId, currency, amount, acceptableRange, loanPeriod, interestRate, collateral, collateralCurrency
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
        //add spotOnContract to the activeSpotOnContracts mapping
        activeSpotOnContracts[spotOnContractId] = newSpotOnContract;

        //add spotOnContract Address to the mapping to track spotOnId to spotOnContract Address
        spotOnContractAddress[spotOnContractId] = address(this);
        return spotOnContractId;
    }

    //----------------------------------Setters---------------------------------------//

    //function set loan start of the spotOnContract
    function setLoanDates(uint256 spotOnContractId, uint256 startDate) public {
        activeSpotOnContracts[spotOnContractId].startDate = startDate;
    }

    //function set repaymentAmount of the spotOnContract
    function setRepaymentAmount(uint256 spotOnContractId, uint256 loanPeriod, uint256 interestRate, uint256 amount) public {
        uint256 monthsBetween = loanPeriod / 30; // Approximate number of months during the loanPeriod
        uint256 totalAmountDue = amount;
        for (uint256 i = 0; i < monthsBetween; i++) {
            totalAmountDue = (totalAmountDue * (interestRate + 100)/100 ) ; // Compounding interest monthly
        }
        activeSpotOnContracts[spotOnContractId].repaymentAmount = totalAmountDue;
    }

    //function to set borrower of the spotOnContract
    function setBorrower(uint256 spotOnContractId, address borrowerAddress) public {
        activeSpotOnContracts[spotOnContractId].borrower = borrowerAddress;
    }

    //funciton to set lender of the spotOnContract
    function setLender(uint256 spotOnContractId, address lenderAddress) public {
        activeSpotOnContracts[spotOnContractId].lender = lenderAddress;
    }

    //function to set amount of the spotOnContract
    function setAmount(uint256 spotOnContractId, uint256 newAmount) public {
        activeSpotOnContracts[spotOnContractId].amount = newAmount;
    }

    //function to add collateral to the spotOnContract
    function addCollateral(uint256 spotOnContractId, uint256 collateralAmount) public {
        activeSpotOnContracts[spotOnContractId].collateral += collateralAmount;
    }

    //--------------------------------------Getters----------------------------------//

    //function to get contract address of the spotOnContract
    function getSpotOnContractAddress(uint256 spotOnContractId) public view returns(address) {
        return spotOnContractAddress[spotOnContractId];
    }

    //function to get repayment amount of the spotOnContract
    function getSpotOnContractRepaymentAmount(uint256 spotOnContractId) public view returns(uint256) {
        return activeSpotOnContracts[spotOnContractId].repaymentAmount;
    }

    //function to get lender of the spotOnContract
    function getSpotOnLender(uint256 spotOnContractId) public view returns(address) {
        return activeSpotOnContracts[spotOnContractId].lender;
    }

    //function to get borrower of the spotOnContract
    function getSpotOnBorrower(uint256 spotOnContractId) public view returns(address) {
        return activeSpotOnContracts[spotOnContractId].borrower;
    }

    //function to get currency type of the spotOnContract
    function getCurrencyType(uint256 spotOnContractId) public view returns(uint256) {
        return activeSpotOnContracts[spotOnContractId].currency;
    }

    //function to get collateral amount of the spotOnContract
    function getCollateralAmount(uint256 spotOnContractId) public view returns(uint256) {
        return activeSpotOnContracts[spotOnContractId].collateral;
    }

    //function to get collateral currency of the spotOnContract
    function getCollateralCurrency(uint256 spotOnContractId) public view returns(uint256) {
        return activeSpotOnContracts[spotOnContractId].collateralCurrency;
    }

    //function to get amount of the spotOnContract
    function getAmount(uint256 spotOnContractId) public view returns(uint256) {
        return activeSpotOnContracts[spotOnContractId].amount;
    }

    //function to get loan period of the spotOnContract
    function getLoanPeriod(uint256 spotOnContractId) public view returns(uint256) {
        return activeSpotOnContracts[spotOnContractId].loadPeriod;
    }

    //function to get interest rate of the spotOnContract
    function getInterestRate(uint256 spotOnContractId) public view returns(uint256) {
        return activeSpotOnContracts[spotOnContractId].interestRate;
    }

    //function to get acceptable range of the spotOnContract
    function getAcceptableRange(uint256 spotOnContractId) public view returns(uint256) {
        return activeSpotOnContracts[spotOnContractId].acceptableRange;
    }

    //function to get timestamp 
    function getTimeStamp() public view returns(uint) {
        return block.timestamp;
    }

}
