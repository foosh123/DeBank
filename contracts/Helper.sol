pragma solidity >= 0.5.0;

import "./ERC20.sol";
import "./DSMath.sol";
import "./PriceConsumer.sol";
import "./RNG.sol";
import "./Cro.sol";
import "./Shib.sol";
import "./Uni.sol";

// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Helper {

    ERC20 erc20Contract;
    RNG r = new RNG();
    Cro cro = new Cro();
    Shib shib = new Shib();
    Uni uni = new Uni();
    string public currentConversion;
    uint256 public platformFee;
    uint256 public transactionFee;
    //  constructor() public {
    //     // platformFee = platFee;
    //     // transactionFee = transFee;
    // }

    function setCurrencyConversion(string memory conversion) public { // {'btc_usd', etc}
        currentConversion = conversion;
    }

    function setPlatformFee(uint256 amt) public {
        platformFee = amt;
    }

    function setTransactionFee(uint256 amt) public {
        transactionFee = amt;
    }

    //before using, check if address to charge has more than the platform fee
    function chargePlatformFee(uint256 choiceOfCurrency, address user, address recipient) public payable {
        if(choiceOfCurrency == 0) { //means its token1
            require(cro.checkBalance(user) >= platformFee, "Insufficient tokens");
            cro.sendToken(user, recipient, platformFee);
        } else if(choiceOfCurrency == 1) {
            require(shib.checkBalance(user) >= platformFee, "Insufficient tokens");
            shib.sendToken(user, recipient, platformFee);  
        } else if(choiceOfCurrency == 2) {
            require(uni.checkBalance(user) >= platformFee, "Insufficient tokens");
            uni.sendToken(user, recipient, platformFee); 
        }
    }

    //before using, check if address to charge has more than the transaction fee
    function chargeTransactionFee(int tokenType, address user, address recipient) public payable {
        if(choiceOfCurrency == 0) { //means its token1
            require(cro.checkBalance(user) >= transactionFee, "Insufficient tokens");
            cro.sendToken(user, recipient, transactionFee);
        } else if(choiceOfCurrency == 1) {
            require(shib.checkBalance(user) >= transactionFee, "Insufficient tokens");
            shib.sendToken(user, recipient, transactionFee);  
        } else if(choiceOfCurrency == 2) {
            require(uni.checkBalance(user) >= transactionFee, "Insufficient tokens");
            uni.sendToken(user, recipient, transactionFee); 
        }
    }        

    function withdrawFee(uint256 choiceOfCurrency, uint256 amt, address from) public {
        if(choiceOfCurrency == 0) { //choiceOfCurrency == 0 
            require(cro.checkBalance(from) >= amt, "Insufficient tokens");
            cro.sendToken(from, msg.sender, amt);
        } else if(choiceOfCurrency == 1) {
            require(shib.checkBalance(from) >= amt, "Insufficient tokens");
            shib.sendToken(from, msg.sender, amt);
        } else if(choiceOfCurrency == 2) {
            require(uni.checkBalance(from) >= amt, "Insufficient tokens");
            uni.sendToken(from, msg.sender, amt);
    }

}
