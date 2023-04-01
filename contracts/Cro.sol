pragma solidity ^0.5.0;
import "./ERC20.sol";

contract Cro {
    ERC20 erc20Contract;
    uint256 supplyLimt;
    uint256 currentSupply;
    address owner;
    
    constructor() public {
        ERC20 e = new ERC20();
        erc20Contract = e;
        owner = msg.sender;
        //100k supply
        supplyLimt = 100000;
    }

    //1CRO = 0.01ETH
    function getToken() public payable {
        uint256 amt = msg.value/10000000000000000;
        require(erc20Contract.totalSupply() + amt < supplyLimt, "CRO supply is not enough");
        erc20Contract.mint(msg.sender, amt);
    }

    function checkBalance() public view returns(uint256) {
        return erc20Contract.balanceOf(msg.sender);
    }

    function sendToken(address from, address to, uint256 amt) public{   
        erc20Contract.transferFrom(from,to,amt);
    }
}