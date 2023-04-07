pragma solidity >= 0.5.0;

import "./ERC20.sol";
import "./DSMath.sol";
import "./PriceConsumer.sol";
// import "./RNG.sol";
import "./Cro.sol";
import "./Shib.sol";
import "./Uni.sol";

// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Helper {

    // ERC20 erc20Contract;
    // RNG r = new RNG();
    Cro cro = new Cro();
    Shib shib = new Shib();
    Uni uni = new Uni();
    uint256 public platformFee; //in ether
    uint256 public transactionFee; //in ether
    //  constructor() public {
    //     // platformFee = platFee;
    //     // transactionFee = transFee;
    // }

    // function setCurrencyConversion(string memory conversion) public {
    //     currentConversion = conversion;
    // }

    // function setPlatformFee(uint256 amt) public {
    //     platformFee = amt;
    // }

    // function setTransactionFee(uint256 amt) public {
    //     transactionFee = amt;
    // }

    //before using, check if address to charge has more than the platform fee
    function chargePlatformFee(uint256 choiceOfCurrency, address user, address recipient) public payable {
        platformFee = 100;
        if(choiceOfCurrency == 0) { 
            uint256 convertedFee = platformFee/100;
            require(cro.checkBalance(user) >= convertedFee, "Insufficient tokens");
            cro.sendToken(user, recipient, convertedFee);
        } else if(choiceOfCurrency == 1) {
            uint256 convertedFee = platformFee/10000;
            require(shib.checkBalance(user) >= convertedFee, "Insufficient tokens");
            shib.sendToken(user, recipient, convertedFee);  
        } else if(choiceOfCurrency == 2) {
            uint256 convertedFee = platformFee/10;
            require(uni.checkBalance(user) >= convertedFee, "Insufficient tokens");
            uni.sendToken(user, recipient, convertedFee); 
        }
    }

    //before using, check if address to charge has more than the transaction fee
    function chargeTransactionFee(uint256 choiceOfCurrency, address user, address recipient) public payable {
        transactionFee = 100;
        if(choiceOfCurrency == 0) { 
            uint256 convertedFee = transactionFee/100;
            require(cro.checkBalance(user) >= convertedFee, "Insufficient tokens");
            cro.sendToken(user, recipient, convertedFee);
        } else if(choiceOfCurrency == 1) {
            uint256 convertedFee = transactionFee/10000;
            require(shib.checkBalance(user) >= convertedFee, "Insufficient tokens");
            shib.sendToken(user, recipient, convertedFee);  
        } else if(choiceOfCurrency == 2) {
            uint256 convertedFee = transactionFee/10;
            require(uni.checkBalance(user) >= convertedFee, "Insufficient tokens");
            uni.sendToken(user, recipient, convertedFee); 
            }
    }  

    function withdrawFee(uint256 choiceOfCurrency, uint256 amt, address from) public {
        if(choiceOfCurrency == 0) { 
            uint256 convertedAmt = amt/100;
            require(cro.checkBalance(from) >= convertedAmt, "Insufficient tokens");
            cro.sendToken(from, msg.sender, convertedAmt);
        } else if(choiceOfCurrency == 1) {
            uint256 convertedAmt = amt/10000;
            require(shib.checkBalance(from) >= convertedAmt, "Insufficient tokens");
            shib.sendToken(from, msg.sender, convertedAmt);
        } else if(choiceOfCurrency == 2) {
            uint256 convertedAmt = amt/10;
            require(uni.checkBalance(from) >= convertedAmt, "Insufficient tokens");
            uni.sendToken(from, msg.sender, convertedAmt);
        }
    }   
}
