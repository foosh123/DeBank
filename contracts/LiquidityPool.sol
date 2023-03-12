pragma solidity >= 0.5.0;

// import './ERC20.sol';

contract LiquidityPool {

    enum currency { BTC, ETH, BNB, USDT, SOL, XRP }

    uint256 poolAmount;
    uint256 borrowerInterestRate;
    uint256 lenderInterestRate;

    address[] borrowersList;
    address[] lendersList;
    
    mapping(address => uint256) public borrowers;
    mapping(address => uint256) public lenders;

    constructor() public {
        poolAmount = 0;
        borrowerInterestRate = 0;
        lenderInterestRate = 0;
    }

    event DepositMade(address lender, currency choiceOfCurrency, uint256 depositAmount);
    event WithdrawalMade(address borrower, currency choiceOfCurrency, uint256 withdrawnAmount);

    function checkBalance() public view returns (uint256) {
        return poolAmount;
    }

    function depositToLiquidityPool(currency choiceOfCurrency, uint256 depositAmount) public {

        require (depositAmount > 0, "Can't deposit 0 tokens");

        uint256 existingAmount = lenders[msg.sender];
        if (existingAmount != 0) {
            existingAmount += depositAmount;
        } else {
            existingAmount = depositAmount;
        }

        poolAmount += depositAmount;
        lenders[msg.sender] = existingAmount;
        lendersList.push(msg.sender);

        emit DepositMade(msg.sender, choiceOfCurrency, depositAmount);
    }

    function withdrawFromLiquidityPool(currency choiceOfCurrency, uint256 withdrawalAmount) public {

        require (lenders[msg.sender] >= withdrawalAmount, "Not enough tokens to withdraw");

        uint256 existingAmount = lenders[msg.sender];
        existingAmount -= withdrawalAmount;
        poolAmount -= withdrawalAmount;
        lenders[msg.sender] = existingAmount;

        emit WithdrawalMade(msg.sender, choiceOfCurrency, withdrawalAmount);
    }

    function getNumberOfBorrowers() public view returns (uint256) {
        return borrowersList.length;
    }

    function getNumberOfLenders() public view returns (uint256) {
        return lendersList.length;
    }

    function getBorrowerLoanAmount(address borrower) public view returns (uint256) {
        return borrowers[borrower];
    }

    function getLenderLoanAmount(address lender) public view returns (uint256) {
        return lenders[lender];
    }

    function getBorrowerInterestRate() public view returns (uint256) {
        return borrowerInterestRate;
    }

    function getLenderInterestRate() public view returns (uint256) {
        return lenderInterestRate;
    }


}