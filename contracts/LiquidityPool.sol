// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0;
import "./ERC20.sol";
import "./RNG.sol";
import "./Cro.sol";
import "./Shib.sol";
import "./Uni.sol";
import "./DeBank.sol";

contract LiquidityPool {
    
    RNG r;
    Cro cro;
    Shib shib;
    Uni uni;
    DeBank deBankContract;

    constructor(DeBank deBankAddress, RNG rngAddress, Cro croAddress, Shib shibAdress, Uni uniAddress) { 
        deBankContract = deBankAddress; 
        r = rngAddress; 
        cro = croAddress;
        shib = shibAdress;
        uni = uniAddress;
    }

    struct Deposit {
        uint256 amount;
        uint256 time;
        uint256 currencyType;
    }

    struct Loan {
        uint256 amount;
        uint256 time;
        // uint256 interestRate;
        uint256 currencyType;
    }

    struct liquidityPool {
        uint256 poolLoanId;   
        string currencyTypeName;
        uint256 poolAmount;       
        uint256 borrowerInterestRate;
        uint256 lenderInterestRate;
        uint256 transactionFee;
    }

    struct Collateral {
        uint256 currencyType; //the one wanna borrow
        uint256 collateralCurrencyType; // what type the collateral is for
        uint256 amount;
    }

    address _owner = msg.sender;
    address[] borrowerList;
    address[] lenderList;
    uint256 public numPools = 0;
    mapping(uint256 => liquidityPool) public pools;

    mapping(address => Deposit[]) deposits;
    mapping(address => mapping(uint256 => uint256)) balances; 
    
    mapping(address => Loan[]) loans;
    mapping(address => mapping(uint256 => uint256)) borrowedAmounts; 
    mapping(address => Collateral[]) collateralAmounts; 

    event DepositMade(address lender, uint256 choiceOfCurrency, uint256 depositAmount);
    event LoanBorrowed(address borrower, uint256 choiceOfCurrency, uint256 loanAmount);
    event WithdrawalMade(address lender, uint256 choiceOfCurrency, uint256 withdrawnAmount);
    event LoanReturned(address borrower, uint256 choiceOfCurrency, uint256 returnedAmount);
    event MarginCallWarningSent(address borrower, uint256 choiceOfCurrency);
    event CollateralLiquidated(address borrower, uint256 choiceOfCurrency);
    event LogOwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfered(uint choiceOfCurrency, uint256 amount);
    event Log(string message);
    event Log2(uint256 message);
    event NewLiquidityPoolAdded(string name);
    

    // modifier to ensure a function is callable only by its owner    
    modifier ownerOnly() {
        require(msg.sender == _owner);
        _;
    }

    // modifier to ensure a function can only be called by a registered user of the platform
    modifier userOnly() {
        bool result = deBankContract.checkUser(msg.sender);
        require(result == true);
        _;
    }

    // modifier to ensure the currency is initiated by the contract 
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

    // modifier to ensure lender exist
    modifier isValidLender(address lender) {
        bool isValid = false;
        for (uint i=0; i < lenderList.length; i++) {
            if(lenderList[i] == lender) {
                isValid = true;
            }
        }
        require (isValid == true, "Invalid Lender Adrress!");
        _;
    }

    // modifier to ensure borrower exist
    modifier isValidBorrower(address lender) {
        bool isValid = false;
        for (uint i=0; i < borrowerList.length; i++) {
            if(borrowerList[i] == lender) {
                isValid = true;
            }
        }
        require (isValid == true, "Invalid Borrower Adrress!");
        _;
    }

    // transfer ownership 
    function transferOwnership(address newOwner) public ownerOnly {
        require(newOwner != _owner, "You can't transfer to the same address");
        emit LogOwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    // Only owner can create pools
    function addNewPool(
        string memory currencyTypeName,
        uint256 transactionFee
    ) public payable ownerOnly returns(uint256) {
        require(msg.sender == _owner, "Only Liquidity Pool contract Owner can add new pool");
        
        //new pool object
        liquidityPool memory newLiquidityPool = liquidityPool(
            numPools,
            currencyTypeName,
            0,     
            0,
            0,
            transactionFee
        );
        
        pools[numPools] = newLiquidityPool; //commit to state variable
        numPools++;
        
        emit NewLiquidityPoolAdded(currencyTypeName);
        
        return numPools;   //return new poolId
    }

    function checkPoolAmount (uint choiceOfCurrency) public isValidCurrency(choiceOfCurrency) view returns (uint256) {
        return pools[choiceOfCurrency].poolAmount;
    }

    // Function to deposit funds
    function deposit(uint256 choiceOfCurrency, uint256 depositAmount, uint256 time) public isValidCurrency(choiceOfCurrency) userOnly {
        
        require(depositAmount > 0, "Deposit amount must be greater than 0");
        
        // update lenders
        if (doesLenderExist(msg.sender) == false) {
            lenderList.push(msg.sender);
        }

        //transfer the token
        depositToken(choiceOfCurrency, depositAmount);

        // Each withdrawal will incur a fixed amount of transaction fees
        // Transaction fee is initialised during pool creation and can be set/update by owner 
        uint256 transactionFee = getTransactionFee(choiceOfCurrency);

        // Create a new deposit struct and add it to the deposits mapping for this user
        Deposit memory d= Deposit(depositAmount-transactionFee, time, choiceOfCurrency);
        deposits[msg.sender].push(d);
        
        // Add the deposited amount to the user's balance for the specified currency
        balances[msg.sender][choiceOfCurrency] += (depositAmount-transactionFee);
        // Add the deposited amount to total pool
        pools[choiceOfCurrency].poolAmount += depositAmount;

        emit DepositMade(msg.sender, choiceOfCurrency, depositAmount);
    }

    // Function to withdraw funds
    function withdraw(uint256 amount, uint256 choiceOfCurrency) isValidCurrency(choiceOfCurrency) isValidLender(msg.sender) public userOnly{
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(balances[msg.sender][choiceOfCurrency] >= amount, "Insufficient balance");

        // Each withdrawal will incur a fixed amount of transaction fees
        // Transaction fee is initialised during pool creation and can be set/update by owner 
        uint256 transactionFee = getTransactionFee(choiceOfCurrency);

        // transfer the token
        withdrawToken(choiceOfCurrency, (amount-transactionFee));

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
    function calculateInterest(uint256 currentTime) public ownerOnly {
        for (uint i = 0; i < lenderList.length; i++ ) {
            address lender = lenderList[i];
            for (uint j = 0; j < numPools; j++) {
                uint256 choiceOfCurrency = j;
                uint256 totalBalance = balances[lender][choiceOfCurrency];
                uint256 interest = 0;
                if (totalBalance > 0) {
                    for (uint k = 0; k < getDepositCount(lender, choiceOfCurrency); k++) {
                        Deposit memory d = deposits[lender][k];
                        if (d.currencyType == choiceOfCurrency) {
                            uint256 timeElapsed = currentTime - d.time;
                            uint256 secondsInMonth = 2592000; // assuming 30 days in a month
                            uint256 monthsElapsed = timeElapsed / secondsInMonth;
                            interest += (d.amount * getLenderInterestRate(j) * monthsElapsed) / 100;
                        }
                    }
                    if (interest > 0) {
                        // deposit(j,interest, currentTime);
                        // require(depositAmount > 0, "Deposit amount must be greater than 0");

                        // Create a new deposit struct and add it to the deposits mapping for this user
                        Deposit memory d= Deposit(interest, currentTime, choiceOfCurrency);
                        deposits[lender].push(d);

                        //transfer the token
                        // depositToken(j, interest);
                        
                        // Add the deposited amount to the user's balance for the specified currency
                        balances[lender][choiceOfCurrency] += interest;
                        // Add the deposited amount to total pool
                        pools[choiceOfCurrency].poolAmount += interest;

                        emit DepositMade(lender, choiceOfCurrency, interest);
                    }
                }
            }
        }
    }

    // Function to get the number of deposits made by the user for a specified currency
    function getDepositCount(address user, uint256 currencyType) internal view returns (uint256) {
        uint256 count = 0;
        for (uint i = 0; i < deposits[user].length; i++) {
            if (deposits[user][i].currencyType == currencyType) {
                count++;
            }
        }
        return count;
    }

    // Function to get the number of loans made by the user for a specified currency
    function getLoanCount(address user, uint256 currencyType) internal view returns (uint256) {
        uint256 count = 0;
        for (uint i = 0; i < loans[user].length; i++) {
            if (loans[user][i].currencyType == currencyType) {
                count++;
            }
        }
        return count;
    }

    // Function to borrow funds
    function borrow(uint256 loanAmount, uint256 choiceOfCurrency, uint256 time) public isValidCurrency(choiceOfCurrency) userOnly {
        require(loanAmount > 0, "Loan amount must be greater than 0");

        // a. check how much colleteral needed based on currency type
        // b. check if got enuf of that amt 
        Collateral memory collateral = getBorrowerCollateral(choiceOfCurrency, msg.sender);
        uint256 collateralAmount = collateral.amount;
        uint256 collateralCurrency = collateral.collateralCurrencyType;

        require(collateralAmount > 0, "Insufficient collateral to borrow 1");
        require(deBankContract.returnRatio(choiceOfCurrency, loanAmount, collateralCurrency, collateralAmount) >= DSMath.wdiv(3,2)/10**16, "Insufficient collateral to borrow 2");

        // update borrowers
        if (doesBorrowerExist(msg.sender) == false) {
            borrowerList.push(msg.sender);
        }

        // Create a new loan struct and add it to the loans mapping for this user
        Loan memory loan = Loan(loanAmount, time, choiceOfCurrency);
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
    function returnLoan(uint256 amount, uint256 choiceOfCurrency) public isValidCurrency(choiceOfCurrency) isValidBorrower(msg.sender) userOnly {
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

            removeUserFromUserList(borrowerList, msg.sender);
        }

        emit LoanReturned(msg.sender, choiceOfCurrency, amount);
    }

    function getBorrowerCollateral (uint256 choiceOfCurrency, address borrower) public view  isValidCurrency(choiceOfCurrency) returns (Collateral memory) {
        Collateral memory collateral;
        for (uint i = 0; i < collateralAmounts[borrower].length; i++) {
            if (collateralAmounts[borrower][i].collateralCurrencyType == choiceOfCurrency) 
                {
                    collateral = collateralAmounts[borrower][i];
                }
        }
        return collateral;
    }

    function depositCollateral (uint256 currencyType, uint256 currencyFor, uint256 amount) isValidCurrency(currencyType) public {
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
            collateralAmounts[msg.sender].push(c);
        }

        depositToken(currencyType, amount);
    }

    // Function to calculate the interest owed on a user's loan for a specified currency
    function calculateLoanInterest(uint256 currentTime) public ownerOnly {
        for (uint i = 0; i < borrowerList.length; i++) {
            address borrower = borrowerList[i];
            calculateLoanInterestForBorrower(currentTime, borrower);
        }
        
    }

    // Function to calculate the interest owed on a user's loan for a specified currency
    function calculateLoanInterestForBorrower(uint256 currentTime, address borrower) public ownerOnly {
        for (uint j = 0; j < numPools; j++) {
            uint256 choiceOfCurrency = j;
            uint256 totalLoanAmount = borrowedAmounts[borrower][choiceOfCurrency];
            uint256 interest = 0;
            if (totalLoanAmount > 0) {
                for (uint k = 0; k < getLoanCount(borrower, choiceOfCurrency); k++) {
                    Loan memory l = loans[borrower][k];
                    if (l.currencyType == choiceOfCurrency) {
                        uint256 timeElapsed = currentTime - l.time;
                        uint256 secondsInMonth = 2592000; // assuming 30 days in a month
                        uint256 monthsElapsed = timeElapsed / secondsInMonth;

                        interest += (totalLoanAmount * getBorrowerInterestRate(choiceOfCurrency) * monthsElapsed) / 100;
                    }
                }
                if (interest > 0) {
                    // Create a new loan struct and add it to the loans mapping for this user
                    Loan memory loan = Loan(interest, currentTime, choiceOfCurrency);
                    loans[borrower].push(loan);

                    // transfer the token
                    withdrawToken(choiceOfCurrency, interest);

                    // Add the loan amount to the user's borrowedAmounts for the specified currency
                    borrowedAmounts[borrower][choiceOfCurrency] += interest;
                    // Remove loan amount from total pool
                    pools[choiceOfCurrency].poolAmount -= interest;

                    emit LoanBorrowed(borrower, choiceOfCurrency, interest);
                    totalLoanAmount = borrowedAmounts[borrower][choiceOfCurrency];
                }
                marginCall (borrower, choiceOfCurrency, totalLoanAmount);
            }
        }
        
        
    }

    function marginCall (address borrower, uint256 choiceOfCurrency, uint256 totalLoanAmount) public {
        // go through borrowerList, get the currency loan, check against the collateral using rate x, y
        // margin call OR liquidate accordingly 
        Collateral memory collateral = getBorrowerCollateral(choiceOfCurrency, borrower); //msg.sender
        uint256 collateralAmount = collateral.amount;
        uint256 collateralCurrency = collateral.currencyType;

        require(totalLoanAmount > 0, "total Loan Amount must be more than 0");

        if (deBankContract.returnRatio(choiceOfCurrency, totalLoanAmount, collateralCurrency, collateralAmount) <= DSMath.wdiv(21,20)/10**16) { // [Margin Call] 1.05: liquidate
            liquidateCollateral(borrower, choiceOfCurrency);
            emit CollateralLiquidated (borrower, choiceOfCurrency);
        } else if (deBankContract.returnRatio(choiceOfCurrency, totalLoanAmount, collateralCurrency, collateralAmount) <= DSMath.wdiv(6,5)/10**16) { // [Margin Call] 1.2: gives warning
            emit Log ("WARNING: Collateral ratio has dropped below 1.2! If ratio falls further below 1.05, your collateral will be liquidated!");
            emit MarginCallWarningSent (borrower, choiceOfCurrency);
        } 
    }

    // Function to liquidate collateral when value ratio falls below trashhold
    function liquidateCollateral(address borrower, uint256 currencyFor) private {
        // [Margin call] If < x1.05, liquidate (move the amount to the pool), and borrowers can keep the loan amount
        removeCollateralFromCollateralList(collateralAmounts[borrower], currencyFor);
    }

    //--------------Helper Methods----------------
    function approveSpender (address spender, uint256 amt) public ownerOnly {
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
            cro.sendToken(msg.sender, address(this), amt);
            // cro.sendToken(address(this), amt);
            emit Transfered(choiceOfCurrency, amt);
        } else if(choiceOfCurrency == 1) {
            require(shib.checkBalance(msg.sender) >= amt, "You dont have enough token to deposit");
            shib.sendToken(msg.sender, address(this), amt);
            emit Transfered(choiceOfCurrency, amt);
        } else if(choiceOfCurrency == 2) {
            require(uni.checkBalance(msg.sender) >= amt, "You dont have enough token to deposit");
            uni.sendToken(msg.sender, address(this), amt);
            // uni.sendToken(address(this), amt);
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

    function setDepositTime(Deposit memory d, uint256 timestamp) public pure {
        d.time = timestamp;
    }

    function setTransactionFee (uint256 choiceOfCurrency, uint256 fee) public ownerOnly isValidCurrency(choiceOfCurrency){
        pools[choiceOfCurrency].transactionFee = fee;
    }

    //----------getter methods-------------
    function getContractOwner() public view returns(address) {
       return _owner;
    }

    function getCurrencyName(uint256 choiceOfCurrency) public view isValidCurrency(choiceOfCurrency) returns (string memory) {
        require (choiceOfCurrency < numPools, "Invalid Currency Type");
        return pools[choiceOfCurrency].currencyTypeName;
    }

    function getAllCurrency() public view returns (string memory) {
        string memory output = "";
        bool first = true;
        for (uint256 i = 0; i < numPools; i++) {
            if(first == true) {
                output = pools[i].currencyTypeName;
                first = false;
            } else {
                output = string(abi.encodePacked(output, ", ", pools[i].currencyTypeName));
            }
        }
        return output;
    }
    
    // Function to get the user's loan balance for a specified currency
    function getLoanBalance(address user, uint256 choiceOfCurrency) public view isValidCurrency(choiceOfCurrency) returns (uint256) {
        return borrowedAmounts[user][choiceOfCurrency];
    }

    // Function to get the user's balance for a specified currency
    function getBalance(address user, uint256 choiceOfCurrency) public view isValidCurrency(choiceOfCurrency) returns (uint256) {
        require (user == msg.sender || _owner == msg.sender, "You are not authorised to access the balance");
        return balances[user][choiceOfCurrency];
    }

    function getBorrowerInterestRate(uint choiceOfCurrency) public view isValidCurrency(choiceOfCurrency) returns (uint256) {
        return pools[choiceOfCurrency].borrowerInterestRate;
    }

    function getLenderInterestRate(uint choiceOfCurrency) public view isValidCurrency(choiceOfCurrency) returns (uint256) {
        return pools[choiceOfCurrency].lenderInterestRate;
    }

    function getLenderDeposits(address Lender) public view returns (Deposit[] memory) {
        return deposits[Lender];
    }

    function getCollateralAmountForCurrency (address borrower, uint256 choiceOfCurrency) public isValidCurrency(choiceOfCurrency) view returns (uint256){
        uint256 collateralAmount = 0;
        for (uint i = 0; i < collateralAmounts[borrower].length; i++) {
            if (collateralAmounts[borrower][i].collateralCurrencyType == choiceOfCurrency) {
                collateralAmount = collateralAmounts[borrower][i].amount;
                break;
            }
        }
        return collateralAmount;
    }

    function getTransactionFee (uint256 choiceOfCurrency) public isValidCurrency(choiceOfCurrency) view returns(uint256) {
        return pools[choiceOfCurrency].transactionFee;
    }

    function removeUserFromUserList(address[] storage arr, address add) internal {
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
        uint index = 0;
        for (uint i = 0; i < arr.length; i++) {
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