pragma solidity >= 0.5.0;
// pragma experimental ABIEncoderV2;
import "./ERC20.sol";
import "./DSMath.sol";
import "./RNG.sol";

contract LiquidityPool {

    // { BTC, ETH, BNB, USDT, SOL, XRP }

    // address[] borrowersList;
    // address[] lendersList;
    address public owner;
    string[] currencyTypes;
    RNG r = new RNG();

    // mapping(string => uint256) poolAmounts;
    // mapping(string => uint256) borrowerInterestRates;
    // mapping(string => uint256) lenderInterestRates;

    mapping(uint256 => mapping(address => uint256)) borrowers;
    mapping(uint256 => mapping(address => uint256)) lenders;  
    // uint256 poolLoanIdCount = 0;
    // mapping(address => uint256) public borrowers;
    // mapping(address => uint256) public lenders;

    // mapping(address => string) borrowerCurrencyType;
    // mapping(address => string) lenderCurrencyType;

    // constructor() public {
    //     poolAmount = 0;
    //     borrowerInterestRate = 0;
    //     lenderInterestRate = 0;
    // }

    struct liquidityPool {
        string currencyType;
        uint256 poolAmount;       
        uint256 borrowerInterestRate;
        uint256 lenderInterestRate;
        address owner;
        address prevOwner;
        uint256 poolLoanId;
        // mapping(address => uint256) borrowers;
        // mapping(address => uint256) lenders;        
    }

    uint256 public numPools = 0;
    mapping(string => liquidityPool) public pools;

    event DepositMade(address lender, string choiceOfCurrency, uint256 depositAmount);
    event WithdrawalMade(address borrower, string choiceOfCurrency, uint256 withdrawnAmount);
    event LogOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    //modifier to ensure a function is callable only by its owner    
    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }

    function Owned() public {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public ownerOnly {
        require(newOwner != address(0));
        emit LogOwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // Only owner can create pools
    function addNewPool(
        string memory currencyType
        // uint256 borrowerInterestRate, // change to API
        // uint256 lenderInterestRate // change to API
    ) public payable ownerOnly returns(uint256) {
        // require(numberOfSides > 0);
        //require((msg.value) > 0.00 ether, "Please deposit a minimum amount to initiate a new currency pool");
        
        //new pool object
        liquidityPool memory newLiquidityPool = liquidityPool(
            currencyType,
            msg.value,     
            0,
            0,
            msg.sender,  //owner
            address(0), //prev owner
            numPools
        );
        
        numPools++;
        // uint256 newPoolId = numPools++;
        pools[currencyType] = newLiquidityPool; //commit to state variable
        currencyTypes.push(currencyType);
        return numPools;   //return new poolId
    }

    // modifier validLoanId(uint256 loanId) {
    //     require(loanId < numLoans);
    //     _;
    // }

    function checkPoolAmount (string memory choiceOfCurrency) public view returns (uint256) {
        return pools[choiceOfCurrency].poolAmount;
    }

    // function getListOfCurrencyTypes() public view returns (string memory) {
    //     string memory result = "";
    //     for (uint i=0; i<currencyTypes.length; i++) {
    //         string.concat(result, currencyTypes[i]);
    //     }        
    //     return result;
    // }

    function depositToLiquidityPool(string memory choiceOfCurrency, uint256 depositAmount) public {

        liquidityPool storage pool = pools[choiceOfCurrency];

        bool isValidCurrency = false;
        for (uint i=0; i<currencyTypes.length; i++) {
            if(keccak256(abi.encodePacked(currencyTypes[i]))==keccak256(abi.encodePacked(choiceOfCurrency))) {
                isValidCurrency = true;
            }
        }
        require (isValidCurrency == true, "The Currency is not supported yet!");
        require (depositAmount > 0, "Can't deposit 0 tokens");
        
        // uint256 existingAmount = pool.lenders[msg.sender];
        pool.lenders[msg.sender] += depositAmount;

        pool.poolAmount += depositAmount;
        // pool.lenders[msg.sender] = existingAmount;
        // pool.lendersList.push(msg.sender);

        emit DepositMade(msg.sender, choiceOfCurrency, depositAmount);
    }

    function withdrawFromLiquidityPool(string memory choiceOfCurrency, uint256 withdrawalAmount) public {

        liquidityPool storage pool = pools[choiceOfCurrency];
        bool isValidCurrency = false;
        for (uint i=0; i<currencyTypes.length; i++) {
            if(keccak256(abi.encodePacked(currencyTypes[i]))==keccak256(abi.encodePacked(choiceOfCurrency))) {
                isValidCurrency = true;
            }
        }
        require (isValidCurrency == true, "The Currency is not supported yet!");
        require (pool.lenders[msg.sender] >= withdrawalAmount, "Not enough tokens to withdraw");

        pool.lenders[msg.sender] = pool.lenders[msg.sender] - withdrawalAmount;
        pool.poolAmount -= withdrawalAmount;

        emit WithdrawalMade(msg.sender, choiceOfCurrency, withdrawalAmount);
    }

    //----------setter methods-------------
    function setLenderInterestRate(string memory choiceOfCurrency) public {
        // RNG.setRandomNumber(mockInterst);
        
        pools[choiceOfCurrency].lenderInterestRate =  r.generateRandonNumber();
    }

    function setBorrowerInterestRate(string memory choiceOfCurrency) public {
        // RNG.setRandomNumber(mockInterst);
        pools[choiceOfCurrency].borrowerInterestRate =  r.generateRandonNumber();
    }

    //----------getter methods-------------
    function getBorrowerLoanAmount(string memory choiceOfCurrency, address borrower) public view returns (uint256) {
        return pools[choiceOfCurrency].borrowers[borrower];
    }

    function getLenderLoanAmount(string memory choiceOfCurrency, address lender) public view returns (uint256) {
        return pools[choiceOfCurrency].lenders[lender];
    }


    function getBorrowerInterestRate(string memory choiceOfCurrency) public view returns (uint256) {
        return pools[choiceOfCurrency].borrowerInterestRate;
    }

    function getLenderInterestRate(string memory choiceOfCurrency) public view returns (uint256) {
        return pools[choiceOfCurrency].lenderInterestRate;
    }

    //transfer ???
    // function transfer(address newOwner, ) public ownerOnly(loanId) validLoanId(loanId) {
    //     loans[loanId].prevOwner = loans[loanId].owner;
    //     loans[loanId].owner = newOwner;
    // }

}