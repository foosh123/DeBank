pragma solidity >= 0.5.0;

contract Savings {
    struct Deposit {
        uint256 amount;
        uint256 timestamp;
        uint256 currencyType;
    }
    
    struct Loan {
        uint256 amount;
        uint256 timestamp;
        uint256 interestRate;
        uint256 currencyType;
    }
    
    mapping(address => mapping(uint256 => uint256)) balances;
    mapping(address => mapping(uint256 => uint256)) borrowedAmounts;
    mapping(address => Deposit[]) deposits;
    mapping(address => Loan[]) loans;
    
    // Set the monthly interest rate to 1%
    uint256 private interestRate = 1;
    uint256 private loanInterestRate = 2;
    
    // Function to deposit funds
    function deposit(uint256 amount, uint256 currencyType) public {
        require(amount > 0, "Deposit amount must be greater than 0");
        balances[msg.sender][currencyType] += amount;
        Deposit memory deposit = Deposit(amount, block.timestamp, currencyType);
        deposits[msg.sender].push(deposit);
    }
    
    // Function to calculate interest earned on a user's balance for a specified currency
    function calculateInterest(address user, uint256 currencyType) public view returns (uint256) {
        uint256 totalBalance = balances[user][currencyType];
        uint256 interest = 0;
        if (totalBalance > 0) {
            uint256 timeElapsed = block.timestamp - deposits[user][getDepositCount(user, currencyType) - 1].timestamp;
            uint256 secondsInMonth = 2592000; // assuming 30 days in a month
            uint256 monthsElapsed = timeElapsed / secondsInMonth;
            interest += (totalBalance * interestRate * monthsElapsed) / 100;
        }
        return interest;
    }
    
    // Function to get the user's balance for a specified currency
    function getBalance(address user, uint256 currencyType) public view returns (uint256) {
        return balances[user][currencyType];
    }
    
    // Function to get the user's total balance (including interest) for a specified currency
    function getTotalBalance(address user, uint256 currencyType) public view returns (uint256) {
        uint256 balance = balances[user][currencyType];
        uint256 interest = calculateInterest(user, currencyType);
        return balance + interest;
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
    function borrow(uint256 amount, uint256 currencyType) public {
        require(amount > 0, "Loan amount must be greater than 0");
        uint256 balance = balances[msg.sender][currencyType];
        require(balance >= amount, "Insufficient balance");
        // Create a new loan struct and add it to the loans mapping for this user
        Loan memory loan = Loan(amount, block.timestamp, loanInterestRate, currencyType);
        loans[msg.sender].push(loan);
        borrowedAmounts[msg.sender][currencyType] += amount;
        balances[msg.sender][currencyType] -= amount;
    }

    // Function to calculate the interest owed on a user's loan for a specified currency
    function calculateLoanInterest(address user, uint256 currencyType) public view returns (uint256) {
        uint256 totalLoanAmount = borrowedAmounts[user][currencyType];
        uint256 interest = 0;
        if (totalLoanAmount > 0) {
            uint256 timeElapsed = block.timestamp - loans[user][getLoanCount(user, currencyType) - 1].timestamp;
            uint256 secondsInMonth = 2592000; // assuming 30 days in a month
            uint256 monthsElapsed = timeElapsed / secondsInMonth;
            interest += (totalLoanAmount * loans[user][getLoanCount(user, currencyType) - 1].interestRate * monthsElapsed) / 100;
        }
        return interest;
    }

    // Function to get the user's loan balance for a specified currency
    function getLoanBalance(address user, uint256 currencyType) public view returns (uint256) {
        return borrowedAmounts[user][currencyType];
    }

    // Function to get the user's total loan balance (including interest) for a specified currency
    function getTotalLoanBalance(address user, uint256 currencyType) public view returns (uint256) {
        uint256 loanBalance = borrowedAmounts[user][currencyType];
        uint256 loanInterest = calculateLoanInterest(user, currencyType);
        return loanBalance + loanInterest;
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

    // Function to withdraw funds
    function withdraw(uint256 amount, uint256 currencyType) public {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(balances[msg.sender][currencyType] >= amount, "Insufficient balance");
        balances[msg.sender][currencyType] -= amount;
        // Update the deposit amount for the specified currency
        for (uint i = 0; i < deposits[msg.sender].length; i++) {
            if (deposits[msg.sender][i].currencyType == currencyType) {
                if (deposits[msg.sender][i].amount >= amount) {
                    deposits[msg.sender][i].amount -= amount;
                    break;
                } else {
                    amount -= deposits[msg.sender][i].amount;
                    deposits[msg.sender][i].amount = 0;
                }
            }
        }
    }

}