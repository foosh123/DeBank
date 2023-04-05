pragma solidity >= 0.5.0;
// pragma experimental ABIEncoderV2;
import "./ERC20.sol";
import "./DSMath.sol";
import "./RNG.sol";
import "./Cro.sol";
import "./Shib.sol";
import "./Uni.sol";

contract LiquidityPool {

    address public owner;
    string[] currencyTypes;
    RNG r = new RNG();
    Cro cro = new Cro();
    Shib shib = new Shib();
    Uni uni = new Uni();

    mapping(uint256 => mapping(address => uint256)) borrowers;
    mapping(uint256 => mapping(address => uint256)) lenders;  

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
    event LoanBorrowed(address borrower, string choiceOfCurrency, uint256 borrowAmount);
    event WithdrawalMade(address lender, string choiceOfCurrency, uint256 withdrawnAmount);
    event LoanReturned(address borrower, string choiceOfCurrency, uint256 returnAmount);
    event LogOwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfered(string choiceOfCurrency, uint256 amount);
    

    //modifier to ensure a function is callable only by its owner    
    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
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
    ) public payable ownerOnly returns(uint256) {
        //require(numberOfSides > 0);
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

    //-------------Lender Mentods-----------------------
    function depositToLiquidityPool(string memory choiceOfCurrency, uint256 depositAmount) public isValidCurrency(choiceOfCurrency) {

        liquidityPool storage pool = pools[choiceOfCurrency];
        uint256 poolLoanId = getLenderPoolLoanId(choiceOfCurrency);

        require (depositAmount > 0, "Can't deposit 0 tokens");

        //transfer token to pool
        depositToken(choiceOfCurrency, depositAmount);

        // uint256 existingAmount = pool.lenders[msg.sender];
        lenders[poolLoanId][msg.sender] += depositAmount;
        // pool.lenders[msg.sender] += depositAmount;

        pool.poolAmount += depositAmount;
        // pool.lenders[msg.sender] = existingAmount;
        // pool.lendersList.push(msg.sender);

        emit DepositMade(msg.sender, choiceOfCurrency, depositAmount);
    }

    function withdrawFromLiquidityPool(string memory choiceOfCurrency, uint256 withdrawalAmount) public isValidCurrency(choiceOfCurrency) {

        liquidityPool storage pool = pools[choiceOfCurrency];
        uint256 poolLoanId = getLenderPoolLoanId(choiceOfCurrency);

        require (lenders[poolLoanId][msg.sender] >= withdrawalAmount, "Not enough tokens to withdraw");

        //transfer token to pool
        withdrawToken(choiceOfCurrency, withdrawalAmount);

        lenders[poolLoanId][msg.sender] = lenders[poolLoanId][msg.sender] - withdrawalAmount;
        pool.poolAmount -= withdrawalAmount;

        emit WithdrawalMade(msg.sender, choiceOfCurrency, withdrawalAmount);
    }

    //-------------Borrower Mentods-----------------------
    function borrowFromLiquidityPool(string memory choiceOfCurrency, uint256 amt) public isValidCurrency(choiceOfCurrency) {

        liquidityPool storage pool = pools[choiceOfCurrency];
        uint256 poolLoanId = getLenderPoolLoanId(choiceOfCurrency);

        require (amt > 0, "Can't borrow 0 tokens");
        
        //transfer token to pool
        withdrawToken(choiceOfCurrency, amt);

        borrowers[poolLoanId][msg.sender] += amt;
        pool.poolAmount -= amt;

        emit LoanBorrowed(msg.sender, choiceOfCurrency, amt);
    }

    function returnToLiquidityPool(string memory choiceOfCurrency, uint256 amt) public isValidCurrency(choiceOfCurrency) {

        liquidityPool storage pool = pools[choiceOfCurrency];
        uint256 poolLoanId = getLenderPoolLoanId(choiceOfCurrency);

        require (borrowers[poolLoanId][msg.sender] < amt, "Too many tokens returned");

        //transfer token to pool
        depositToken(choiceOfCurrency, amt);

        borrowers[poolLoanId][msg.sender] = borrowers[poolLoanId][msg.sender] - amt;
        pool.poolAmount += amt;

        emit LoanReturned(msg.sender, choiceOfCurrency, amt);
    }

    //-----------Pool Token Transfer Methods-----------------
    function depositToken(string memory choiceOfCurrency, uint256 amt) public isValidCurrency(choiceOfCurrency) {
        if(keccak256(abi.encodePacked(choiceOfCurrency))==keccak256(abi.encodePacked("Cro")) ) {
            require(cro.checkBalance() >= amt, "You dont have enough token to deposit");
            cro.sendToken(msg.sender, address(this), amt);
            emit Transfered(choiceOfCurrency, amt);
        } else if(keccak256(abi.encodePacked(choiceOfCurrency))==keccak256(abi.encodePacked("Shib")) ) {
            require(shib.checkBalance() >= amt, "You dont have enough token to deposit");
            shib.sendToken(msg.sender, address(this), amt);
            emit Transfered(choiceOfCurrency, amt);
        } else if(keccak256(abi.encodePacked(choiceOfCurrency))==keccak256(abi.encodePacked("Uni")) ) {
            require(uni.checkBalance() >= amt, "You dont have enough token to deposit");
            uni.sendToken(msg.sender, address(this), amt);
            emit Transfered(choiceOfCurrency, amt);
        } 
    }

    function withdrawToken(string memory choiceOfCurrency, uint256 amt) public isValidCurrency(choiceOfCurrency) {
        if(keccak256(abi.encodePacked(choiceOfCurrency))==keccak256(abi.encodePacked("Cro")) ) {
            require(cro.checkBalance() >= amt, "You dont have enough token to deposit");
            cro.sendToken(address(this), msg.sender, amt);
            emit Transfered(choiceOfCurrency, amt);
        } else if(keccak256(abi.encodePacked(choiceOfCurrency))==keccak256(abi.encodePacked("Shib")) ) {
            require(shib.checkBalance() >= amt, "You dont have enough token to deposit");
            shib.sendToken(address(this), msg.sender, amt);
            emit Transfered(choiceOfCurrency, amt);
        } else if(keccak256(abi.encodePacked(choiceOfCurrency))==keccak256(abi.encodePacked("Uni")) ) {
            require(uni.checkBalance() >= amt, "You dont have enough token to deposit");
            uni.sendToken(address(this), msg.sender, amt);
            emit Transfered(choiceOfCurrency, amt);
        } 
    }

    //----------setter methods-------------
    function setLenderInterestRate(string memory choiceOfCurrency) public isValidCurrency(choiceOfCurrency) {
        // RNG.setRandomNumber(mockInterst);
        
        pools[choiceOfCurrency].lenderInterestRate =  r.generateRandonNumber();
    }

    function setBorrowerInterestRate(string memory choiceOfCurrency) public isValidCurrency(choiceOfCurrency) {
        // RNG.setRandomNumber(mockInterst);
        pools[choiceOfCurrency].borrowerInterestRate =  r.generateRandonNumber();
    }

    //----------getter methods-------------
    function getBorrowerPoolLoanId(string memory choiceOfCurrency) public view returns (uint256) {
        return pools[choiceOfCurrency].poolLoanId;
    }

    function getLenderPoolLoanId(string memory choiceOfCurrency) public view returns (uint256) {
        return pools[choiceOfCurrency].poolLoanId;
    }

    function getBorrowerLoanAmount(string memory choiceOfCurrency, address borrower) public view returns (uint256) {
        uint256 poolLoanId = getBorrowerPoolLoanId(choiceOfCurrency);
        return borrowers[poolLoanId][borrower];
        // return pools[choiceOfCurrency].borrowers[borrower];
    }

    function getLenderLoanAmount(string memory choiceOfCurrency, address lender) public view returns (uint256) {
        uint256 poolLoanId = getLenderPoolLoanId(choiceOfCurrency);
        return lenders[poolLoanId][lender];
        // return pools[choiceOfCurrency].lenders[lender];
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