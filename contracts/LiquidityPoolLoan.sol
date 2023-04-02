pragma solidity >= 0.5.0;

// import './ERC20.sol';

contract LiquidityPoolLoan {

    // enum currency { BTC, ETH, BNB, USDT, SOL, XRP}
    enum loanType { lend, borrow}

    string[] currencyPoolId; 
    

    struct liquidityPoolLoan {
        loanType loanType;
        address loaner;
        // currency currency;
        uint256 amount;
        // uint256 startedDate;
        // address owner;
        // address prevOwner;
        // Ex1
    }

    event created (uint256 loadId);
    event settled (uint256 loadId);

    uint256 public numLoans = 0;
    mapping(uint256 => liquidityPoolLoan) public loans;

    function createLoan(
        loanType lType,
        currency cur,
        uint256 amount
    ) public payable returns(uint256) {
        // require(numberOfSides > 0);
        require((msg.value - amount) > 0.01 ether, "You need to pay 0.03% of platform fee.");
        
        //new dice object
        liquidityPoolLoan memory newLiquidityPoolLoan = liquidityPoolLoan(
            lType,
            cur,
            amount,
            (uint256)(block.timestamp),
            msg.sender,  //owner
            address(0) //prev owner
        );
        
        uint256 newLoanId = numLoans++;
        loans[newLoanId] = newLiquidityPoolLoan; //commit to state variable
        return newLoanId;   //return new loanId
    }

    //modifier to ensure a function is callable only by its owner  
    modifier ownerOnly(uint256 loanId) {
        require(loans[loanId].owner == msg.sender);
        _;
    }

    modifier validLoanId(uint256 loanId) {
        require(loanId < numLoans);
        _;
    }

    //compound interest 
    function compoundInteret(uint256 loanId) public view ownerOnly(loanId) validLoanId(loanId) {
        if(loans[loanId].loanType == loanType.lend) {
            
        } else {

        }
    }


    //
    function settleLoan(uint256 loanId) public ownerOnly(loanId) validLoanId(loanId) {

        //return contract to Pool Loan
        if(loans[loanId].loanType == loanType.lend) {
            //transfer amount from pool to lender 
        } else {
            //transfer amount from borrower to pool 
        }
    }

    //transfer ownership to new owner
    function transfer(uint256 loanId, address newOwner) public ownerOnly(loanId) validLoanId(loanId) {
        loans[loanId].prevOwner = loans[loanId].owner;
        loans[loanId].owner = newOwner;
    }
}