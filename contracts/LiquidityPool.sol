// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0;
// pragma experimental ABIEncoderV2;
import "./ERC20.sol";
// import "./DSMath.sol";
import "./RNG.sol";
import "./Cro.sol";
import "./Shib.sol";
import "./Uni.sol";
import "./Debank.sol";
import "./Helper.sol";

contract LiquidityPool {
    
    RNG r;
    Cro cro;
    Shib shib;
    Uni uni;
    Debank deBankContract;
    Helper helperContract;

    constructor(Debank deBankAddress, RNG rngAddress, Cro croAddress, Shib shibAdress, Uni uniAddress, Helper helperAddress) public { 
        deBankContract = deBankAddress; 
        r = rngAddress; 
        cro = croAddress;
        shib = shibAdress;
        uni = uniAddress;
        helperContract = helperAddress;
    }

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
        uint256 poolLoanId;   
        string currencyTypeName;
        uint256 poolAmount;       
        uint256 borrowerInterestRate;
        uint256 lenderInterestRate;
        // address owner;
        // address prevOwner;
    }

    struct Collateral {
        uint256 currencyType; //the one wanna borrow
        uint256 collateralCurrencyType; // what type the collateral is for
        uint256 amount;
    }

    address _owner = msg.sender;
    // uint256[] numPools;
    address[] borrowerList;
    address[] lenderList;
    uint256 public numPools = 0;
    mapping(uint256 => liquidityPool) public pools;

    mapping(address => Deposit[]) deposits;
    mapping(address => mapping(uint256 => uint256)) balances; //userAddress => (currencyType => amount)
    
    mapping(address => Loan[]) loans;
    mapping(address => mapping(uint256 => uint256)) borrowedAmounts; //userAddress => (currencyType => amount)
    mapping(address => Collateral[]) collateralAmounts; //userAddress => (currencyType => amount)

    event DepositMade(address lender, uint256 choiceOfCurrency, uint256 depositAmount);
    event LoanBorrowed(address borrower, uint256 choiceOfCurrency, uint256 loanAmount);
    event WithdrawalMade(address lender, uint256 choiceOfCurrency, uint256 withdrawnAmount);
    event LoanReturned(address borrower, uint256 choiceOfCurrency, uint256 returnedAmount);
    event LogOwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfered(uint choiceOfCurrency, uint256 amount);
    event Log(string message);
    event Log2(uint256 message);
    event NewLiquidityPoolAdded(string name);
    

    //modifier to ensure a function is callable only by its owner    
    modifier ownerOnly() {
        require(msg.sender == _owner);
        _;
    }

    modifier isValidCurrency(uint256 currencyType) {
        bool isValid = false;
        for (uint i=0; i < numPools; i++) {
            if(currencyType == i) {
                isValid = true;
            }
        }
        require (isValid == true, "The Currency is not supported yet!");
        _;
    }

    function transferOwnership(address newOwner) public ownerOnly {
        require(newOwner != address(0));
        emit LogOwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    // Only owner can create pools
    function addNewPool(
        string memory currencyTypeName
    ) public payable ownerOnly returns(uint256) {
        //require(numberOfSides > 0);
        // require((amount) > 0.00 ether, "Please deposit a minimum amount to initiate a new currency pool!");
        // require(cro.checkBalance() >= amount, "You do not have enought currency token!");
        require(msg.sender == _owner, "Only Liquidity Pool contract Owner can add new pool");
        
        //new pool object
        liquidityPool memory newLiquidityPool = liquidityPool(
            numPools,
            currencyTypeName,
            0,     
            0,
            0
            // msg.sender,  //owner
            // address(0) //prev owner
        );
        
        pools[numPools] = newLiquidityPool; //commit to state variable
        // numPools.push(currencyType);
        numPools++;
        
        emit NewLiquidityPoolAdded(currencyTypeName);
        
        return numPools;   //return new poolId
    }

    function checkPoolAmount (uint choiceOfCurrency) public view returns (uint256) {
        return pools[choiceOfCurrency].poolAmount;
    }

    // Function to deposit funds
    function deposit(uint256 choiceOfCurrency, uint256 depositAmount, uint256 time) public {// isValidCurrency(choiceOfCurrency) 
        // A 0.05% of platform fee will be charged
        //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        
        // uint256 platformFee = helperContract.;
        require(depositAmount > 0, "Deposit amount must be greater than 0");
        
        // update lenders
        if (doesLenderExist(msg.sender) == false) {
            lenderList.push(msg.sender);
        }

        // Create a new deposit struct and add it to the deposits mapping for this user
        Deposit memory d= Deposit(depositAmount, time, choiceOfCurrency);
        deposits[msg.sender].push(d);

        //transfer the token
        depositToken(choiceOfCurrency, depositAmount);
        
        // Add the deposited amount to the user's balance for the specified currency
        balances[msg.sender][choiceOfCurrency] += depositAmount;
        // Add the deposited amount to total pool
        pools[choiceOfCurrency].poolAmount += depositAmount;

        emit DepositMade(msg.sender, choiceOfCurrency, depositAmount);
    }

    // Function to withdraw funds
    function withdraw(uint256 amount, uint256 choiceOfCurrency) public {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(balances[msg.sender][choiceOfCurrency] >= amount, "Insufficient balance");

        
        // Each withdrawal will incur a fixed amount of transaction fees {$10 USD}
        //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

        // transfer the token
        withdrawToken(choiceOfCurrency, amount);

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


        // Return amount to total pool
        pools[choiceOfCurrency].poolAmount -= amount;

        // Check if all currency balance empty, True -> Remove user
        bool isEmpty = true;
        for (uint i = 0; i < numPools; i++) {
            if (balances[msg.sender][i] == 0) {
                isEmpty = false;
                break;
            }
        }
        if (isEmpty) {
            removeUserFromUserList(lenderList, msg.sender);
        }


        emit WithdrawalMade(msg.sender, choiceOfCurrency, amount);
    }

    // Function to calculate interest earned on a user's balance for a specified currency
    function calculateInterest(uint256 interestRate, uint256 currentTime) public {
        for (uint i = 0; i < lenderList.length; i++ ) { 
            for (uint j = 0; j < numPools; j++) {
                uint256 totalBalance = balances[lenderList[i]][j];
                uint256 interest = 0;
                if (totalBalance > 0) {
                    for (uint k = 0; k < getDepositCount(lenderList[i], j); k++) {
                        Deposit memory d = deposits[lenderList[i]][k];
                        if (d.currencyType == j) {
                            uint256 timeElapsed = currentTime - d.time;
                            uint256 secondsInMonth = 2592000; // assuming 30 days in a month
                            uint256 monthsElapsed = timeElapsed / secondsInMonth;
                            interest += (d.amount * interestRate * monthsElapsed) / 100;
                        }
                    }
                    if (interest > 0) {
                        // deposit(j,interest, currentTime);
                        // require(depositAmount > 0, "Deposit amount must be greater than 0");

                        // Create a new deposit struct and add it to the deposits mapping for this user
                        Deposit memory d= Deposit(interest, currentTime, j);
                        deposits[lenderList[i]].push(d);

                        //transfer the token
                        // depositToken(j, interest);
                        
                        // Add the deposited amount to the user's balance for the specified currency
                        balances[lenderList[i]][j] += interest;
                        // Add the deposited amount to total pool
                        pools[j].poolAmount += interest;

                        emit DepositMade(lenderList[i], j, interest);
                    }
                }
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

    // Function to get the number of loans made by the user for a specified currency
    function getLoanCount(address user, uint256 currencyType) public view returns (uint256) {
        uint256 count = 0;
        for (uint i = 0; i < loans[user].length; i++) {
            if (loans[user][i].currencyType == currencyType) {
                count++;
            }
        }
        return count;
    }

    // Function to borrow funds
    function borrow(uint256 loanAmount, uint256 choiceOfCurrency) public {
        require(loanAmount > 0, "Loan amount must be greater than 0");

        // a. check how much colleteral needed based on currency type
        // b. check if got enuf of that amt 
        Collateral memory collateral = getBorrowerCollateral(choiceOfCurrency);
        uint256 collateralAmount = collateral.amount;
        uint256 collateralCurrency = collateral.collateralCurrencyType;

        require(deBankContract.returnRatio(choiceOfCurrency, loanAmount, collateralCurrency, collateralAmount) >= DSMath.wdiv(3,2), "Insufficient collateral to borrow");

        // update borrowers
        if (doesBorrowerExist(msg.sender) == false) {
            borrowerList.push(msg.sender);
        }

        // Create a new loan struct and add it to the loans mapping for this user
        Loan memory loan = Loan(loanAmount, block.timestamp, getBorrowerInterestRate(choiceOfCurrency), choiceOfCurrency);
        loans[msg.sender].push(loan);

        // transfer the token
        withdrawToken(choiceOfCurrency, loanAmount);

        // Add the loan amount to the user's borrowedAmounts for the specified currency
        borrowedAmounts[msg.sender][choiceOfCurrency] += loanAmount;
        // Remove loan amount from total pool
        pools[choiceOfCurrency].poolAmount -= loanAmount;

        emit LoanBorrowed(msg.sender, choiceOfCurrency, loanAmount);
    }

    // Function to return loan
    function returnLoan(uint256 amount, uint256 choiceOfCurrency) public {
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
        depositToken(choiceOfCurrency, amount);

        // Return amount to total pool
        pools[choiceOfCurrency].poolAmount += amount;

        // !!!!!!!!!!!!! ADD IN !!!!!!!!!!!!!!!
        // Return Funds
            //  a. need to return collateral per ratio
            //  b. if all loan is cleared, must remove the Collateral instance from the collateralAmount array (use pop)
        uint256 totalLoanAmount = borrowedAmounts[msg.sender][choiceOfCurrency];
        if (totalLoanAmount == 0) {
            removeCollateralFromCollateralList(collateralAmounts[msg.sender], choiceOfCurrency);
        }

        // Check if all currency balance empty, True -> Remove user
        bool isEmpty = true;
        for (uint i = 0; i < numPools; i++) {
            if (borrowedAmounts[msg.sender][i] == 0) {
                isEmpty = false;
                break;
            }
        }
        if (isEmpty) {
            // delete borrowerList[msg.sender];
            removeUserFromUserList(borrowerList, msg.sender);
        }

        emit LoanReturned(msg.sender, choiceOfCurrency, amount);
    }

    function getBorrowerCollateral (uint256 choiceOfCurrency) public view returns (Collateral memory) {
        Collateral memory collateral;
        for (uint i = 0; i <= collateralAmounts[msg.sender].length; i++) {
            if (collateralAmounts[msg.sender][i].collateralCurrencyType == choiceOfCurrency) 
                {
                    collateral = collateralAmounts[msg.sender][i];
                }
        }
        return collateral;
    }

    // !!!!!!!!!! NEED TO ADD IN !!!!!!!!!!!!!!!!!!!!!!!!
    function depositCollateral (uint256 currencyType, uint256 currencyFor, uint256 amount) public {
        //check if borrowing currency has collateral ctype 
        // Yes 
            // check if == currencyType
                // Yes: put in
                // No: error
        // No
            // add in new Collateral
            // add in amount
        
        bool hasCollateral = false;
        Collateral memory c;
        for (uint256 i = 0; i < collateralAmounts[msg.sender].length; i++) {
            if (collateralAmounts[msg.sender][i].collateralCurrencyType == currencyFor) {
                require (collateralAmounts[msg.sender][i].currencyType == currencyType, "Invalid Collateral Currency Type");
                hasCollateral = true;
                c = collateralAmounts[msg.sender][i];
            }
        }
        if (hasCollateral) {
            c.amount += amount;
        } else {
            c.currencyType = currencyType;
            c.collateralCurrencyType = currencyFor;
            c.amount = amount;
            collateralAmounts[msg.sender][currencyFor] = c;
        }

        depositToken(currencyType, amount);
    }

    // Function to calculate the interest owed on a user's loan for a specified currency
    function calculateLoanInterest(uint256 interestRate) public {
        for (uint i = 0; i < borrowerList.length; i++) {
            for (uint j = 0; j < numPools; j++) {
                uint256 totalLoanAmount = borrowedAmounts[borrowerList[i]][j];
                uint256 interest = 0;
                if (totalLoanAmount > 0) {
                    for (uint k = 0; k < getLoanCount(borrowerList[i], j); k++) {
                        Loan memory l = loans[borrowerList[i]][k];
                        if (l.currencyType == j) {
                            uint256 timeElapsed = block.timestamp - l.time;
                            uint256 secondsInMonth = 2592000; // assuming 30 days in a month
                            uint256 monthsElapsed = timeElapsed / secondsInMonth;
                            interest += (totalLoanAmount * interestRate * monthsElapsed) / 100;
                        }
                    }
                    if (interest > 0) {
                        // Create a new loan struct and add it to the loans mapping for this user
                        Loan memory loan = Loan(interest, block.timestamp, getBorrowerInterestRate(j), j);
                        loans[borrowerList[i]].push(loan);

                        // transfer the token
                        withdrawToken(j, interest);

                        // Add the loan amount to the user's borrowedAmounts for the specified currency
                        borrowedAmounts[borrowerList[i]][j] += interest;
                        // Remove loan amount from total pool
                        pools[j].poolAmount -= interest;

                        emit LoanBorrowed(borrowerList[i], j, interest);
                        totalLoanAmount = borrowedAmounts[borrowerList[i]][j];
                    }
                }

                Collateral memory collateral = getBorrowerCollateral(j);
                uint256 collateralAmount = collateral.amount;
                uint256 collateralCurrency = collateral.currencyType;

                // [Margin Call] 1.2: gives warning
                if (deBankContract.returnRatio(j, totalLoanAmount, collateralCurrency, collateralAmount) <= DSMath.wdiv(6,5)) {
                    emit Log ("WARNING: Collateral ratio has dropped below 1.2! If ratio falls further below 1.05, your collateral will be liquidated!");
                } else if (deBankContract.returnRatio(j, totalLoanAmount, collateralCurrency, collateralAmount) <= DSMath.wdiv(21,20)) { // [Margin Call] 1.05: liquidate
                    liquidateCollateral(borrowerList[i], j);
                }
            }
        }
        
    }

    // !!!!!!!!!! NEED TO ADD IN risk checking !!!!!!!!!!!!!!!!!!!!!!!!
    // Function to liquidate collateral when value ratio falls below trashhold
    function liquidateCollateral(address borrower, uint256 currencyFor) private {
        // [Margin call] If < x1.05, liquidate (move the amount to the pool), and borrowers can keep the loan amount
        removeCollateralFromCollateralList(collateralAmounts[borrower], currencyFor);
    }

    //--------------Helper Methods----------------
    function approveSpender (address spender, uint256 amt) public {
        shib.approveSpender(spender, amt);
    }

    // Function to check if lender exists
    function doesLenderExist (address lender) private view returns (bool) {
        bool lenderExists = false;
        for (uint i = 0; i < lenderList.length; i++) {
            if(lenderList[i] == lender) {
                lenderExists = true;
            }
        }
        return lenderExists;
    }

    // Function to check if borrower exists
    function doesBorrowerExist (address borrower) private view returns (bool) {
        bool borrowerExists = false;
        for (uint i = 0; i < borrowerList.length; i++) {
            if(borrowerList[i] == borrower) {
                borrowerExists = true;
            }
        }
        return borrowerExists;
    }


    //-----------Pool Token Transfer Methods-----------------
    function depositToken(uint256 choiceOfCurrency, uint256 amt) public isValidCurrency(choiceOfCurrency) {
        if(choiceOfCurrency == 0) { //choiceOfCurrency == 0 
            require(cro.checkBalance(msg.sender) >= amt, "You dont have enough token to deposit");
            cro.sendToken(address(this), amt);
            emit Transfered(choiceOfCurrency, amt);
        } else if(choiceOfCurrency == 1) {
            require(shib.checkBalance(msg.sender) >= amt, "You dont have enough token to deposit");
            emit Transfered(choiceOfCurrency, amt);
        } else if(choiceOfCurrency == 2) {
            require(uni.checkBalance(msg.sender) >= amt, "You dont have enough token to deposit");
            uni.sendToken(address(this), amt);
            emit Transfered(choiceOfCurrency, amt);
        } 
    }

    function withdrawToken(uint256 choiceOfCurrency, uint256 amt) public isValidCurrency(choiceOfCurrency) {
        if(choiceOfCurrency == 0) { //choiceOfCurrency == 0 
            require(cro.checkBalance(address(this)) >= amt, "Insufficient tokens in pool to withdraw");
            cro.sendToken(address(this), msg.sender, amt);
            emit Transfered(choiceOfCurrency, amt);
        } else if(choiceOfCurrency == 1) {
            require(shib.checkBalance(address(this)) >= amt, "Insufficient tokens in pool to withdraw");
            shib.approveSpender(msg.sender, amt);
            shib.sendToken(address(this), msg.sender, amt);
            emit Transfered(choiceOfCurrency, amt);
        } else if(choiceOfCurrency == 2) {
            require(uni.checkBalance(address(this)) >= amt, "Insufficient tokens in pool to withdraw");
            uni.sendToken(address(this), msg.sender, amt);
            emit Transfered(choiceOfCurrency, amt);
        } 
    }

    //----------setter methods-------------
    function setLenderInterestRate(uint256 choiceOfCurrency) public isValidCurrency(choiceOfCurrency) {
        pools[choiceOfCurrency].lenderInterestRate =  r.generateRandonNumber();
    }

    function setBorrowerInterestRate(uint256 choiceOfCurrency) public isValidCurrency(choiceOfCurrency) {
        pools[choiceOfCurrency].borrowerInterestRate =  r.generateRandonNumber();
    }

    function setDepositTime(Deposit memory d, uint256 timestamp) public {
        d.time = timestamp;
    }

    //----------getter methods-------------
    function getContractOwner() public view returns(address) {
       return _owner;
    }

    function getCurrencyName(uint256 choiceOfCurrency) public view returns (string memory) {
        require (choiceOfCurrency < numPools, "Invalid Currency Type");
        return pools[choiceOfCurrency].currencyTypeName;
        // if (choiceOfCurrency == 0) {
        //     return "Cro";
        // } else if (choiceOfCurrency == 1) {
        //     return "Shib";
        // } else if (choiceOfCurrency == 2) {
        //     return "Uni";
        // } else {
        //     return "Invalid Currency Type";
        // }
    }
    
    // Function to get the user's loan balance for a specified currency
    function getLoanBalance(address user, uint256 currencyType) public view returns (uint256) {
        return borrowedAmounts[user][currencyType];
    }

    // Function to get the user's balance for a specified currency
    function getBalance(address user, uint256 currencyType) public view returns (uint256)  {
        return balances[user][currencyType];
    }

    function getBorrowerInterestRate(uint choiceOfCurrency) public view returns (uint256) {
        return pools[choiceOfCurrency].borrowerInterestRate;
    }

    function getLenderInterestRate(uint choiceOfCurrency) public view returns (uint256) {
        return pools[choiceOfCurrency].lenderInterestRate;
    }

    function getLenderDeposits(address Lender) public view returns (Deposit[] memory) {
        return deposits[Lender];
    }

    function removeUserFromUserList(address[] storage arr, address add) internal {
        // require(index < arr.length, "Index out of range");
        uint index = 0;
        for (uint i = 0; i < arr.length - 1; i++) {
            if (arr[i] == add) {
                index = i;
            }
        }
        for (uint i = index; i < arr.length - 1; i++) {
            arr[i] = arr[i+1];
        }
        arr.pop();
    }

    function removeCollateralFromCollateralList(Collateral[] storage arr, uint256 currencyFor) internal {
        // require(index < arr.length, "Index out of range");
        uint index = 0;
        for (uint i = 0; i < arr.length - 1; i++) {
            if (arr[i].collateralCurrencyType == currencyFor) {
                index = i;
            }
        }
        for (uint i = index; i < arr.length - 1; i++) {
            arr[i] = arr[i+1];
        }
        arr.pop();
    }

}