pragma solidity >= 0.5.0;


contract SpotOnContract {
    string[] currencyTypes;
    

    struct spotOnContract {
        uint256 spotOnContractId;
        string currency;
        uint256 amount;
        uint256 acceptableRange;
        uint256 loadPeriod;
        uint256 interestRate;
        uint256 collateral;
        uint256 startedDate;
        uint256 repaymentDueDate;
        address borrower;
        address lender;  
    }
    uint256 public numOfContracts = 0;
    mapping(uint256 => spotOnContract) public spotOnContracts; // tracks all spotOnContracts


    function getSpotOnLender(uint256 spotOnContractId) public view returns(address) {
        return spotOnContracts[spotOnContractId].lender;
    }

    function getSpotOnBorrower(uint256 spotOnContractId) public view returns(address) {
        return spotOnContracts[spotOnContractId].borrower;
    }

    function getTimeStamp() public view returns(uint) {
        return block.timestamp;
    }

    function getCurrencyType(uint256 spotOnContractId) public view returns(string memory) {
        return spotOnContracts[spotOnContractId].currency;
    }

    function getCollateralAmount(uint256 spotOnContractId) public view returns(uint256) {
        return spotOnContracts[spotOnContractId].collateral;
    }

    function getAmount(uint256 spotOnContractId) public view returns(uint256) {
        return spotOnContracts[spotOnContractId].amount;
    }

    function createContract(
        uint256 amount,
        string memory currency,
        uint256 acceptableRange,
        uint256 loanPeriod,
        uint256 interestRate,
        uint256 collateral
    ) public returns(uint256) {
        uint timeNow = getTimeStamp();
        uint spotOnId = numOfContracts++;
        spotOnContract memory newSpotOnContract = spotOnContract(
            spotOnId,
            currency,
            amount,
            acceptableRange,
            loanPeriod,
            interestRate,
            collateral,
            timeNow,
            timeNow + loanPeriod,
            address(0),
            address(0)
        );
        spotOnContracts[spotOnId] = newSpotOnContract;
        return spotOnId;
    }

    function setBorrower(uint256 spotOnId, address borrowerAddress) public {
        spotOnContracts[spotOnId].borrower = borrowerAddress;
    }

    function setLender(uint256 spotOnId, address lenderAddress) public {
        spotOnContracts[spotOnId].lender = lenderAddress;
    }



}
