pragma solidity >= 0.5.0;
import "./ERC20.sol";

contract Shib {
    ERC20 erc20Contract;
    uint256 supplyLimt;
    uint256 currentSupply;
    address owner;
    
    constructor() public {
        ERC20 e = new ERC20();
        erc20Contract = e;
        owner = msg.sender;
        //100 Mil supply
        supplyLimt = 100000000;
    }

    //1 SHIB = 0.0001 ETH
    function getToken() public payable {
        uint256 amt = msg.value/100000000000000;
        require(erc20Contract.totalSupply() + amt < supplyLimt, "SHIB supply is not enough");
        erc20Contract.mint(msg.sender, amt);
    }

    function checkBalance() public view returns(uint256) {
        return erc20Contract.balanceOf(msg.sender);
    }

    function sendToken(address from, address to, uint256 amt) public{   
        erc20Contract.transferFrom(from,to,amt);
    }
}