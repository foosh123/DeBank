pragma solidity >= 0.5.0;

import "./ERC20.sol";
import "./DSMath.sol";

contract SpotOn {

    struct spotOn {
        uint256 spotOnId;
        string currency;
        uint256 amount;
        uint256 acceptableRange;
        uint256 loadPeriod;
        uint256 interestRate;
        address borrower;
        address lender;   
    }

    event loanRequested (uint256 spotOnId);
    event loanTaken (uint256 spotOnId);

    mapping(uint256 => spotOn) public spotOnLoans;      // tracks all spotOnLoans
    mapping(uint256 => spotOn) public spotOnInContract;  // tracks all loans that have been accepted, to check loanPeriod is valid
    uint256 public numOfLoans = 0;

    function requestLoan(uint256 amount, string currency, uint256 acceptableRange, uint256 interestRate, uint25 loanPeriod) public {
        // creates new spotOn object
        uint256 spotOnId = numOfLoans++;

        spotOn memory newSpotOn = spotOn(
            spotOnId,
            currency,
            amount,
            acceptableRange,
            loanPeriod,
            interestRate,
            msg.sender,
            address(0)
        );

        spotOnLoans[spotOnId] = newSpotOn;
        emit loanRequested(spotOnId);
        return newSpotOn;
    }

    function takeOnLoan(uint256 spotOnId) public {
        // requires 
        // acceptsLoan
        spotOnLoans[spotOnId].lender = msg.sender;
        spotOnInContract[spotOnId] = spotOnId;
        emit loanTaken(spotOnId);

        
    }

    function offerLoan(uint256 amount, uint256 interestRate, uint256 loanPeriod) {
        
        
    }



}