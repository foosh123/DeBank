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
    address[] borrowerList;
    address[] lenderList;
    RNG r = new RNG();
    Cro cro = new Cro();
    Shib shib = new Shib();
    Uni uni = new Uni();

    // mapping(uint256 => mapping(address => uint256)) borrowers;
    // mapping(uint256 => mapping(address => uint256)) lenders;
    // mapping(address => Deposit[]) lendersDeposit; // userAdd => Deposit
    // mapping(address => mapping(uint256 => uint256)) lenderBalances;  //userAddress => (currencyType => amount)
   
    // mapping(address => Deposit[]) borrowersDeposit; // userAdd => Deposit
    // mapping(address => mapping(uint256 => uint256)) borrowersBalances;  //userAddress => (currencyType => amount)
    
    struct Deposit {
        uint256 amount;
        uint256 time;
        uint256 currencyType;
    }

    struct Loan {
        uint256 amount;
        uint256 time;
        uint256 interestRate;
        uint256 currencyType;
    }

    struct liquidityPool {
        string currencyType;
        uint256 poolAmount;       
        uint256 borrowerInterestRate;
        uint256 lenderInterestRate;
        address owner;
        address prevOwner;
        uint256 poolLoanId;      
    }

    mapping(address => Deposit[]) deposits;
    mapping(address => Loan[]) loans;
    mapping(address => mapping(uint256 => uint256)) balances; //userAddress => (currencyType => amount)
    mapping(address => mapping(uint256 => uint256)) borrowedAmounts; //userAddress => (currencyType => amount)

    // Function to deposit funds
    function deposit(uint256 choiceOfCurrency, uint256 depositAmount) public {// isValidCurrency(choiceOfCurrency) 
        require(depositAmount > 0, "Deposit amount must be greater than 0");
        
        // update lenders
        if (doesLenderExist(msg.sender) == false) {
            lenderList.push(msg.sender);
        }

        // Create a new deposit struct and add it to the deposits mapping for this user
        Deposit memory deposit = Deposit(depositAmount, block.timestamp, choiceOfCurrency);
        deposits[msg.sender].push(deposit);

        //transfer the token
        depositToken(choiceOfCurrency, depositAmount);
        
        // Add the deposited amount to the user's balance for the specified currency
        balances[msg.sender][choiceOfCurrency] += depositAmount;
        // Add the deposited amount to total pool
        pools[choiceOfCurrency].poolAmount += depositAmount;
    }

    // Function to withdraw funds
    function withdraw(uint256 amount, uint256 choiceOfCurrency) public {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(balances[msg.sender][choiceOfCurrency] >= amount, "Insufficient balance");
        balances[msg.sender][choiceOfCurrency] -= amount;

        uint256 withdrawnAmount = amount;

        // Update the deposit amount for the specified currency
        for (uint i = 0; i < deposits[msg.sender].length; i++) {
            if (deposits[msg.sender][i].currencyType == choiceOfCurrency) {
                if (deposits[msg.sender][i].amount >= withdrawnAmount) {
                    deposits[msg.sender][i].amount -= withdrawnAmount;
                    break;
                } else {
                    withdrawnAmount -= deposits[msg.sender][i].amount;
                    deposits[msg.sender][i].amount = 0;
                }
            }
        }

        // transfer the token
        withdrawToken(choiceOfCurrency, amount);

        // Return amount to total pool
        pools[choiceOfCurrency].poolAmount -= amount;

        // Check if all currency balance empty, True -> Remove user
        bool isEmpty = true;
        for (int i = 0; i < currencyTypes.length; i++) {
            if (balances[msg.sender][i] == 0) {
                isEmpty = false;
                break;
            }
        }
        if (isEmpty == true) {
            // lenderList.push(msg.sender);
            delete lenderList[msg.sender];
        }
    }

    // Function to calculate interest earned on a user's balance for a specified currency
    function calculateInterest(uint256 interestRate) public {
        for (int i = 0; i < lenderList.length; i++ ) { 
            for (int j = 0; j < currencyTypes; j++) {
                uint256 totalBalance = balances[lenderList[i]][currencyTypes[j]];
                uint256 interest = 0;
                if (totalBalance > 0) {
                    uint256 timeElapsed = block.timestamp - deposits[lenderList[i]][getDepositCount(lenderList[i], currencyTypes[j]) - 1].timestamp;
                    uint256 secondsInMonth = 2592000; // assuming 30 days in a month
                    uint256 monthsElapsed = timeElapsed / secondsInMonth;
                    interest += (totalBalance * interestRate * monthsElapsed) / 100;
                }
                Deposit(currencyTypes[j],interest);
            }
        }
    }

    // Function to get the number of deposits made by the user for a specified currency
    function getDepositCount(address user, uint256 currencyType) public view returns (uint256) {
        uint256 count = 0;
        for (uint i = 0; i < deposits[user].length; i++) {
            if (deposits[user][i].currencyType == currencyType) {
                count++;
            }
        }
        return count;
    }

    // Function to borrow funds
    function borrow(uint256 loanAmount, uint256 choiceOfCurrency) public {
        require(loanAmount > 0, "Loan amount must be greater than 0");

        // update borrowers
        if (doesBorrowerExist(msg.sender) == false) {
            borrowerList.push(msg.sender);
        }

        // Create a new loan struct and add it to the loans mapping for this user
        Loan memory loan = Loan(loanAmount, block.timestamp, getBorrowerInterestRate(choiceOfCurrency), choiceOfCurrency);
        loans[msg.sender].push(loan);

        // transfer the token
        borrowToken(choiceOfCurrency, loanAmount);

        // Add the loan amount to the user's borrowedAmounts for the specified currency
        borrowedAmounts[msg.sender][choiceOfCurrency] += loanAmount;
        // Remove loan amount from total pool
        pools[choiceOfCurrency].poolAmount -= loanAmount;
    }

    // Function to return borrowed funds
    function returnFunds(uint256 amount, uint256 choiceOfCurrency) public {
        require(amount > 0, "Funds returned must be greater than 0");
        require(borrowedAmounts[msg.sender][choiceOfCurrency] <= amount, "Excessive funds returned");

        // Remove the returned amount from the user's borrowedAmounts for the specified currency
        borrowedAmounts[msg.sender][choiceOfCurrency] -= amount;

        uint256 returnedAmount = amount;
        
        // Update the loan amount for the specified currency
        for (uint i = 0; i < loans[msg.sender].length; i++) {
            if (loans[msg.sender][i].currencyType == choiceOfCurrency) {
                if (loans[msg.sender][i].amount >= returnedAmount) {
                    loans[msg.sender][i].amount -= returnedAmount;
                    break;
                } else {
                    returnedAmount -= loans[msg.sender][i].amount;
                    loans[msg.sender][i].amount = 0;
                }
            }
        }

        // transfer the token
        returnToken(choiceOfCurrency, amount);

        // Return amount to total pool
        pools[choiceOfCurrency].poolAmount += amount;
    }

    //--------------Helper Methods----------------
    // Function to check if lender exists
    function doesLenderExist (address lender) private returns (bool) {
        bool lenderExists = false;
        for (int i = 0; i < lenderList.length; i++) {
            if(lenderList[i] == lender) {
                lenderExists = true;
            }
        }
        return lenderExists;
    }

    // Function to check if borrower exists
    function doesBorrowerExist (address borrower) private returns (bool) {
        bool borrowerExists = false;
        for (int i = 0; i < borrowerList.length; i++) {
            if(borrowerList[i] == borrower) {
                borrowerExists = true;
            }
        }
        return borrowerExists;
    }

    //===========================Old code, can refer!!! ==================================================
    uint256 public numPools = 0;
    mapping(uint256 => liquidityPool) public pools;

    event DepositMade(address lender, uint256 choiceOfCurrency, uint256 depositAmount);
    event LoanBorrowed(address borrower, uint256 choiceOfCurrency, uint256 borrowAmount);
    event WithdrawalMade(address lender, uint256 choiceOfCurrency, uint256 withdrawnAmount);
    event LoanReturned(address borrower, uint256 choiceOfCurrency, uint256 returnAmount);
    event LogOwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfered(string choiceOfCurrency, uint256 amount);
    

    //modifier to ensure a function is callable only by its owner    
    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }

    modifier isValidCurrency(uint256 currencyType) {
        bool isValid = false;
        for (uint i=0; i < currencyTypes.length; i++) {
            if(currencyType == i) {
                isValid = true;
            }
        }
        require (isValid == true, "The Currency is not supported yet!");
        _;
    }

    // function Owned() public {
    //     owner = msg.sender;
    // }

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
    function depositToken(uint256 choiceOfCurrency, uint256 amt) public isValidCurrency(choiceOfCurrency) {
        if(choiceOfCurrency == 0) { //choiceOfCurrency == 0 
            require(cro.checkBalance() >= amt, "You dont have enough token to deposit");
            cro.sendToken(msg.sender, address(this), amt);
            emit Transfered(choiceOfCurrency, amt);
        } else if(choiceOfCurrency == 1) {
            require(shib.checkBalance() >= amt, "You dont have enough token to deposit");
            shib.sendToken(msg.sender, address(this), amt);
            emit Transfered(choiceOfCurrency, amt);
        } else if(choiceOfCurrency == 2) {
            require(uni.checkBalance() >= amt, "You dont have enough token to deposit");
            uni.sendToken(msg.sender, address(this), amt);
            emit Transfered(choiceOfCurrency, amt);
        } 
        // if(keccak256(abi.encodePacked(choiceOfCurrency))==keccak256(abi.encodePacked("Cro")) ) { //choiceOfCurrency == 0 
        //     require(cro.checkBalance() >= amt, "You dont have enough token to deposit");
        //     cro.sendToken(msg.sender, address(this), amt);
        //     emit Transfered(choiceOfCurrency, amt);
        // } else if(keccak256(abi.encodePacked(choiceOfCurrency))==keccak256(abi.encodePacked("Shib")) ) {
        //     require(shib.checkBalance() >= amt, "You dont have enough token to deposit");
        //     shib.sendToken(msg.sender, address(this), amt);
        //     emit Transfered(choiceOfCurrency, amt);
        // } else if(keccak256(abi.encodePacked(choiceOfCurrency))==keccak256(abi.encodePacked("Uni")) ) {
        //     require(uni.checkBalance() >= amt, "You dont have enough token to deposit");
        //     uni.sendToken(msg.sender, address(this), amt);
        //     emit Transfered(choiceOfCurrency, amt);
        // } 
    }

    function withdrawToken(uint256 choiceOfCurrency, uint256 amt) public isValidCurrency(choiceOfCurrency) {
        if(choiceOfCurrency == 0) { //choiceOfCurrency == 0 
            require(cro.checkBalance() >= amt, "You dont have enough token to deposit");
            cro.sendToken(address(this), msg.sender, amt);
            emit Transfered(choiceOfCurrency, amt);
        } else if(choiceOfCurrency == 1) {
            require(shib.checkBalance() >= amt, "You dont have enough token to deposit");
            shib.sendToken(address(this), msg.sender, amt);
            emit Transfered(choiceOfCurrency, amt);
        } else if(choiceOfCurrency == 2) {
            require(uni.checkBalance() >= amt, "You dont have enough token to deposit");
            uni.sendToken(address(this), msg.sender, amt);
            emit Transfered(choiceOfCurrency, amt);
        } 
        // if(keccak256(abi.encodePacked(choiceOfCurrency))==keccak256(abi.encodePacked("Cro")) ) {
        //     require(cro.checkBalance() >= amt, "You dont have enough token to deposit");
        //     cro.sendToken(address(this), msg.sender, amt);
        //     emit Transfered(choiceOfCurrency, amt);
        // } else if(keccak256(abi.encodePacked(choiceOfCurrency))==keccak256(abi.encodePacked("Shib")) ) {
        //     require(shib.checkBalance() >= amt, "You dont have enough token to deposit");
        //     shib.sendToken(address(this), msg.sender, amt);
        //     emit Transfered(choiceOfCurrency, amt);
        // } else if(keccak256(abi.encodePacked(choiceOfCurrency))==keccak256(abi.encodePacked("Uni")) ) {
        //     require(uni.checkBalance() >= amt, "You dont have enough token to deposit");
        //     uni.sendToken(address(this), msg.sender, amt);
        //     emit Transfered(choiceOfCurrency, amt);
        // } 
    }

    function borrowToken(uint256 choiceOfCurrency, uint256 amt) public isValidCurrency(choiceOfCurrency) {
        if(choiceOfCurrency == 0) { //choiceOfCurrency == 0 
            require(cro.checkBalance() >= amt, "You dont have enough token to deposit");
            cro.sendToken(address(this), msg.sender, amt);
            emit Transfered(choiceOfCurrency, amt);
        } else if(choiceOfCurrency == 1) {
            require(shib.checkBalance() >= amt, "You dont have enough token to deposit");
            shib.sendToken(address(this), msg.sender, amt);
            emit Transfered(choiceOfCurrency, amt);
        } else if(choiceOfCurrency == 2) {
            require(uni.checkBalance() >= amt, "You dont have enough token to deposit");
            uni.sendToken(address(this), msg.sender, amt);
            emit Transfered(choiceOfCurrency, amt);
        } 
        // if(keccak256(abi.encodePacked(choiceOfCurrency))==keccak256(abi.encodePacked("Cro")) ) {
        //     require(cro.checkBalance() >= amt, "You dont have enough token to deposit");
        //     cro.sendToken(address(this), msg.sender, amt);
        //     emit Transfered(choiceOfCurrency, amt);
        // } else if(keccak256(abi.encodePacked(choiceOfCurrency))==keccak256(abi.encodePacked("Shib")) ) {
        //     require(shib.checkBalance() >= amt, "You dont have enough token to deposit");
        //     shib.sendToken(address(this), msg.sender, amt);
        //     emit Transfered(choiceOfCurrency, amt);
        // } else if(keccak256(abi.encodePacked(choiceOfCurrency))==keccak256(abi.encodePacked("Uni")) ) {
        //     require(uni.checkBalance() >= amt, "You dont have enough token to deposit");
        //     uni.sendToken(address(this), msg.sender, amt);
        //     emit Transfered(choiceOfCurrency, amt);
        // } 
    }

    function returnToken(uint256 choiceOfCurrency, uint256 amt) public isValidCurrency(choiceOfCurrency) {
        if(choiceOfCurrency == 0) { //choiceOfCurrency == 0 
            require(cro.checkBalance() >= amt, "You dont have enough token to deposit");
            cro.sendToken(address(this), msg.sender, amt);
            emit Transfered(choiceOfCurrency, amt);
        } else if(choiceOfCurrency == 1) {
            require(shib.checkBalance() >= amt, "You dont have enough token to deposit");
            shib.sendToken(address(this), msg.sender, amt);
            emit Transfered(choiceOfCurrency, amt);
        } else if(choiceOfCurrency == 2) {
            require(uni.checkBalance() >= amt, "You dont have enough token to deposit");
            uni.sendToken(address(this), msg.sender, amt);
            emit Transfered(choiceOfCurrency, amt);
        } 
        // if(keccak256(abi.encodePacked(choiceOfCurrency))==keccak256(abi.encodePacked("Cro")) ) {
        //     require(cro.checkBalance() >= amt, "You dont have enough token to deposit");
        //     cro.sendToken(address(this), msg.sender, amt);
        //     emit Transfered(choiceOfCurrency, amt);
        // } else if(keccak256(abi.encodePacked(choiceOfCurrency))==keccak256(abi.encodePacked("Shib")) ) {
        //     require(shib.checkBalance() >= amt, "You dont have enough token to deposit");
        //     shib.sendToken(address(this), msg.sender, amt);
        //     emit Transfered(choiceOfCurrency, amt);
        // } else if(keccak256(abi.encodePacked(choiceOfCurrency))==keccak256(abi.encodePacked("Uni")) ) {
        //     require(uni.checkBalance() >= amt, "You dont have enough token to deposit");
        //     uni.sendToken(address(this), msg.sender, amt);
        //     emit Transfered(choiceOfCurrency, amt);
        // } 
    }

    //----------setter methods-------------
    function setLenderInterestRate(uint256 choiceOfCurrency) public isValidCurrency(choiceOfCurrency) {
        pools[choiceOfCurrency].lenderInterestRate =  r.generateRandonNumber();
    }

    function setBorrowerInterestRate(uint256 choiceOfCurrency) public isValidCurrency(choiceOfCurrency) {
        pools[choiceOfCurrency].borrowerInterestRate =  r.generateRandonNumber();
    }

    //----------getter methods-------------
    function getCurrencyName(uint256 choiceOfCurrency) public view returns (string memory) {
        string memory name;
        if (choiceOfCurrency == 0) {
            return "Cro";
        } else if (choiceOfCurrency == 1) {
            return "Shib";
        } else if (choiceOfCurrency == 2) {
            return "Uni";
        } else {
            return "Invalid Currency Type";
        }
    }
    // function getBorrowerPoolLoanId(string memory choiceOfCurrency) public view returns (uint256) {
    //     return pools[choiceOfCurrency].poolLoanId;
    // }

    // function getLenderPoolLoanId(string memory choiceOfCurrency) public view returns (uint256) {
    //     return pools[choiceOfCurrency].poolLoanId;
    // }

    // function getBorrowerLoanAmount(string memory choiceOfCurrency, address borrower) public view returns (uint256) {
    //     uint256 poolLoanId = getBorrowerPoolLoanId(choiceOfCurrency);
    //     return borrowers[poolLoanId][borrower];
    //     // return pools[choiceOfCurrency].borrowers[borrower];
    // }

    // function getLenderLoanAmount(string memory choiceOfCurrency, address lender) public view returns (uint256) {
    //     uint256 poolLoanId = getLenderPoolLoanId(choiceOfCurrency);
    //     return lenders[poolLoanId][lender];
    //     // return pools[choiceOfCurrency].lenders[lender];
    // }
    
    // Function to get the user's loan balance for a specified currency
    function getLoanBalance(address user, uint256 currencyType) public view returns (uint256) {
        return borrowedAmounts[user][currencyType];
    }

    // Function to get the user's balance for a specified currency
    function getBalance(address user, uint256 currencyType) public view returns (uint256) {
        return balances[user][currencyType];
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