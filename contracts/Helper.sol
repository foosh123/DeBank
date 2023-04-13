// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0;

import "./ERC20.sol";
// import "./DSMath.sol";
import "./PriceConsumer.sol";
// import "./RNG.sol";
import "./Cro.sol";
import "./Shib.sol";
import "./Uni.sol";

contract Helper {

    Cro cro = new Cro();
    Shib shib = new Shib();
    Uni uni = new Uni();
    uint256 public platformFee = 100; //in ether
    uint256 public transactionFee = 10; //in ether

    function setTransactionFee(uint256 fee) public {
        transactionFee = fee;
    }

    function getTransactionFee() public view returns (uint256) {
        return transactionFee;
    }


    //before using, check if address to charge has more than the transaction fee
    function chargeTransactionFee(uint256 choiceOfCurrency, address user, address recipient) public payable {
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

    // function getTransactionFeeAmount(uint256 choiceOfCurrency) public pure returns(uint256) {
    //     if(choiceOfCurrency == 0) { 
    //         return 5;
    //     } else if(choiceOfCurrency == 1) {
    //         return 10; 
    //     } else if(choiceOfCurrency == 2) {
    //         return 15;
    //     }
    // }

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
