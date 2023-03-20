pragma solidity >= 0.5.0;

import "./SpotOnContract.sol";

contract SpotOn {

    SpotOnContract spot_on_contract;
    address owner;

    constructor() public {
        // credit
        owner = msg.sender;
    }

    event loanRequested (uint256 spotOnId);
    event loanOffered (uint256 spotOnId);
    event loanTaken (uint256 spotOnId);


    mapping(uint256 => SpotOnContract) public spotOnInContract;  // tracks all loans that have been accepted, to check loanPeriod is valid
    uint256 public numOfLoans = 0;

    function requestLoan(
        uint256 amount, 
        string memory currency, 
        uint256 acceptableRange, 
        uint256 interestRate, 
        uint256 loanPeriod, 
        uint256 collateral) public returns (uint256){
        
        // creates new spotOnContract
        uint256 spotOnId = spot_on_contract.createContract(
            amount, currency, acceptableRange, loanPeriod, interestRate, collateral
        );
        
        spot_on_contract.setBorrower(spotOnId, msg.sender);
        emit loanRequested(spotOnId);
        return spotOnId;
    }

    function takeOnLoan(uint256 spotOnId) public {
        require(spot_on_contract.getSpotOnBorrower(spotOnId) == address(0) || spot_on_contract.getSpotOnLender(spotOnId) == address(0));

        if (spot_on_contract.getSpotOnBorrower(spotOnId) == address(0)) {
            spot_on_contract.setBorrower(spotOnId, msg.sender);
        }

        if (spot_on_contract.getSpotOnLender(spotOnId) == address(0)) {
            spot_on_contract.setLender(spotOnId, msg.sender);
        }

        //handling transaction of money

        
        emit loanTaken(spotOnId);
    }

    function offerLoan(
        uint256 amount, 
        string memory currency, 
        uint256 acceptableRange, 
        uint256 interestRate, 
        uint256 loanPeriod, 
        uint256 collateral) public returns (uint256){

        uint256 spotOnId = spot_on_contract.createContract(
            amount, currency, acceptableRange, loanPeriod, interestRate, collateral
        );

        spot_on_contract.setLender(spotOnId, msg.sender);
        emit loanOffered(spotOnId);(spotOnId);
        return spotOnId;
    }


}