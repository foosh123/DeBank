pragma solidity >= 0.5.0;

import "./ERC20.sol";
import "./DSMath.sol";
import "./PriceConsumerBTCUSD.sol";
// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Helper {

    // struct helper {
    //     uint256 platformFee;
    //     uint256 transactionFee; 
    // }
    PriceConsumerBTCUSD btc_usd;
    string public currentConversion;
    uint256 public platformFee;
    uint256 public transactionFee;
     constructor() public {
        // platformFee = platFee;
        // transactionFee = transFee;
    }

    function setCurrencyConversion(string memory conversion) public { // {'btc_usd', etc}
        currentConversion = conversion;
    }

    function setPlatformFee(uint256 amt) public {
        platformFee = amt;
    }

    function setTransactionFee(uint256 amt) public {
        transactionFee = amt;
    }

    // function getPlatformFee() public view returns (uint256) {
    //     return platformFee;
    // }

    // function getTransactionFee() public view returns (uint256) {
    //     return transactionFee;
    // }

    //assuming that the function that calls for charging platform/transaction fee is called by user
    function chargePlatformFee() public payable {
        //require that user has more money than platform fee
        require(msg.sender.balance >= platformFee);
        address payable recipient = address(uint160(address(this)));
        recipient.transfer(transactionFee); //transferring transaction and platform fees to helper contract?
    }

    function chargeTransactionFee() public payable {
        //require that user has more money than transaction fee
        require(msg.sender.balance >= transactionFee);
        //do we need to check that userID's owner is msg.sender?
        address payable recipient = address(uint160(address(this)));
        recipient.transfer(transactionFee);

    }

    function withdrawFee(string memory currency, uint256 amt) public {
        //might need api for this
        // uint256 convertedAmt = 
        //check if transferring to the correct person
        // msg.sender.transfer(convertedAmt);
    }

}
