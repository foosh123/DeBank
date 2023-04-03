pragma solidity >= 0.5.0;

import "./SpotOnContract.sol";
import "./RNG.sol";
import "./Cro.sol";
import "./Shib.sol";
import "./Uni.sol";

contract SpotOn {

    SpotOnContract spot_on_contract;
    address owner;
    string[] currencyTypes;
    RNG r = new RNG();
    Cro cro = new Cro();
    Shib shib = new Shib();
    Uni uni = new Uni();

    constructor() public {
        // credit
        owner = msg.sender;
    }

    event loanRequested (uint256 spotOnId);
    event loanOffered (uint256 spotOnId);
    event loanTaken (uint256 spotOnId);
    event Transferred(string currencyType, uint amount);


    mapping(uint256 => SpotOnContract) public spotOnContracts;  // tracks all loans that have been accepted, to check loanPeriod is valid
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

        //handling collateral
        string memory currencyType = spot_on_contract.getCurrencyType(spotOnId);
        uint256 collateralAmount = spot_on_contract.getCollateralAmount(spotOnId);
        depositCollateralToSpotOnContract(currencyType, collateralAmount, spotOnId);

        //lender send to borrower
        address borrower = spot_on_contract.getSpotOnBorrower(spotOnId);
        address lender = spot_on_contract.getSpotOnLender(spotOnId);
        uint amount = spot_on_contract.getAmount(spotOnId);
        if(keccak256(abi.encodePacked(currencyType))==keccak256(abi.encodePacked("Cro")) ) {
            require(cro.checkBalance() >= amount, "You dont have enough token to deposit");
            cro.sendToken(lender, borrower, amount);
            emit Transferred(currencyType, amount);
        } else if(keccak256(abi.encodePacked(currencyType))==keccak256(abi.encodePacked("Shib")) ) {
            require(shib.checkBalance() >= amount, "You dont have enough token to deposit");
            shib.sendToken(lender, borrower, amount);
            emit Transferred(currencyType, amount);
        } else if(keccak256(abi.encodePacked(currencyType))==keccak256(abi.encodePacked("Uni")) ) {
            require(uni.checkBalance() >= amount, "You dont have enough token to deposit");
            uni.sendToken(lender, borrower, amount);
            emit Transferred(currencyType, amount);
        } 

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


    modifier isValidCurrency(string memory currencyType) {
        bool isValid = false;
        for (uint i=0; i < currencyTypes.length; i++) {
            if(keccak256(abi.encodePacked(currencyTypes[i]))==keccak256(abi.encodePacked(currencyType))) {
                isValid = true;
            }
        }
        require (isValid == true, "The Currency is not supported yet!");
        _;
    }

    
    function depositCollateralToSpotOnContract(string memory currencyType, uint256 amount, uint256 spotOnContractId) public payable isValidCurrency(currencyType) {
        require (amount > 0, "Can't deposit 0 tokens");
        
        //checks sender is the borrower
        require (msg.sender == spot_on_contract.getSpotOnBorrower(spotOnContractId));

        //transfer the token
        if(keccak256(abi.encodePacked(currencyType))==keccak256(abi.encodePacked("Cro")) ) {
            require(cro.checkBalance() >= amount, "You dont have enough token to deposit");
            cro.sendToken(msg.sender, address(this), amount);
            emit Transferred(currencyType, amount);
        } else if(keccak256(abi.encodePacked(currencyType))==keccak256(abi.encodePacked("Shib")) ) {
            require(shib.checkBalance() >= amount, "You dont have enough token to deposit");
            shib.sendToken(msg.sender, address(this), amount);
            emit Transferred(currencyType, amount);
        } else if(keccak256(abi.encodePacked(currencyType))==keccak256(abi.encodePacked("Uni")) ) {
            require(uni.checkBalance() >= amount, "You dont have enough token to deposit");
            uni.sendToken(msg.sender, address(this), amount);
            emit Transferred(currencyType, amount);
        } 
        
    }
}