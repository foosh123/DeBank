// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0;
import "./RNG.sol";
import "./Cro.sol";
import "./Shib.sol";
import "./Uni.sol";

library DSMath {
    using SafeMath for uint256;
    uint256 constant PRECISION = 10**18;
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x.mul(PRECISION).add(y.div(2)).div(y);
    }
}

contract Debank{
    using DSMath for uint256;
    Cro cro;
    Shib shib;
    Uni uni;
    uint256 croRate;
    uint256 shibRate;
    uint256 uniRate;

    constructor() public {        
        Cro c = new Cro();
        cro = c;
        Shib s = new Shib();
        shib = s;
        Uni u = new Uni();
        uni = u;
    }

    event initializeCroRate(uint256 CroRate);
    event initializeShibRate(uint256 ShibRate);
    event initializeUniRate(uint256 UniRate);
    event Withdraw(uint256 choiceOfCurrency, uint256 amount);


    struct user{
        string name;
        uint256 balance;
        address add;
    }

    uint256 public numUsers = 0;
    mapping(uint256 => user) public Users;

        
    modifier userOnly(uint256 id) {
        require(Users[id].add == msg.sender);
        _;
    }

    modifier validUserId(uint256 id) {
        require(id < numUsers);
        _;
    }

    function initializeCro(uint256 x, uint256 y) public returns (uint256) {
        croRate = DSMath.wdiv(x,y)/10**16;
        emit initializeCroRate(croRate);
        return croRate;
    }

    function initializeShib(uint256 x, uint256 y) public returns (uint256) {
        shibRate = DSMath.wdiv(x,y)/10**16;
        emit initializeShibRate(shibRate);
        return shibRate;
    }

    function initializeUni(uint256 x, uint256 y) public returns (uint256) {
        uniRate = DSMath.wdiv(x,y)/10**16;
        emit initializeUniRate(uniRate);
        return uniRate;
    }


    function register(string memory name) public payable returns(uint256){
        require(msg.value >= 0.01 ether, "at least 0.01 ETH is needed to register");

        user memory newUser = user(
            name,
            msg.value,
            msg.sender
        );

        uint256 newUserId = numUsers++;
        Users[newUserId] = newUser; 
        return newUserId;   

    }

    function getUserAddress(uint256 id) public view returns(address){
        return Users[id].add;
    }

    function checkBalance(uint256 id) public view validUserId(id) returns(uint256){
        return Users[id].balance;
    }

    function deposit(uint256 id)  public payable userOnly(id){
        require(msg.value > 0 ether, "Cannot deposit 0 ETH");
        Users[id].balance += msg.value;
    }

    function withdraw(uint256 id, uint256 amt) public userOnly(id){
        require(amt > 0 , "Cannot withdraw 0 ETH");
        require(amt >= Users[id].balance);
        Users[id].balance -= amt;
        address payable recipient = payable(msg.sender);
        recipient.transfer(amt);
        // msg.sender.transfer(amt);
    }


    function convertToCRO(uint256 id,uint256 amt) public {
        require(Users[id].balance >= amt/100,"You don't have enough ETH");
        cro.getToken(amt);
        Users[id].balance -= amt/100;
    }

    function convertToSHIB(uint256 id,uint256 amt) public {
        require(Users[id].balance >= amt/10000,"You don't have enough ETH");
        shib.getToken(amt);
        Users[id].balance -= amt/10000;
    }

    function convertToUNI(uint256 id,uint256 amt) public {
        require(Users[id].balance >= amt/10,"You don't have enough ETH");
        uni.getToken(amt);
        Users[id].balance -= amt/10;
    }
    function convertBackToETH(uint256 choiceOfCurrency, uint256 id, uint256 amt) public {
        if(choiceOfCurrency == 0) {
            require(cro.checkBalance() >= amt, "You dont have enough CRO");
            cro.sendToken(address(this),amt);
            Users[id].balance += amt/100;
            emit Withdraw(choiceOfCurrency, amt);
        } else if(choiceOfCurrency == 1) {
            require(shib.checkBalance() >= amt, "You dont have enough SHIB");
            shib.sendToken(msg.sender,address(this), amt);
            Users[id].balance += amt/10000;
            emit Withdraw(choiceOfCurrency, amt);
        } else if(choiceOfCurrency == 2) {
            require(uni.checkBalance() >= amt, "You dont have enough UNI");
            uni.sendToken(msg.sender, address(this), amt);
            Users[id].balance += amt/10;
            emit Withdraw(choiceOfCurrency, amt);
        } 
    }

    function returnRatio(uint256 currencyType, uint256 amount, uint256 collateralCurrency, uint256 collateralAmount) public view returns (uint256) { 
        if (currencyType == 0) { 
            amount = croRate * amount; 
        } else if (currencyType == 1) { 
            amount = shibRate * amount; 
        } else if (currencyType == 2) {  
            amount = uniRate * amount; 
        } 

        if (collateralCurrency == 0) { 
            collateralAmount = croRate * collateralAmount; 
        } else if (collateralCurrency == 1) { 
            collateralAmount = shibRate * collateralAmount; 
        } else if (collateralCurrency == 2) { 
            collateralAmount = uniRate * collateralAmount;             
        } 
 
        return collateralAmount.wdiv(amount)/10**16; 
    }

    function getCroRate() public view returns(uint256) {
        return croRate;
    }

    function getShibRate() public view returns(uint256) {
        return shibRate;
    }

    function getUniRate() public view returns(uint256) {
        return uniRate;
    }

}

