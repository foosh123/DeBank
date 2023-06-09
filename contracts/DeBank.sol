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

contract DeBank{
    using DSMath for uint256;
    Cro cro;
    Shib shib;
    Uni uni;
    uint256 croRate;
    uint256 shibRate;
    uint256 uniRate;
    uint256 public transactionFee;

    function setTransactionFee(uint256 fee) public {
        transactionFee = fee;
    }

    function getTransactionFee() public view returns (uint256) {
        return transactionFee;
    }

    //
    constructor() {        
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
    event registerUser(uint256 id);
    event Withdraw(uint256 choiceOfCurrency, uint256 amount);

    //Creates a user data structure to store name, balance and address
    struct user{
        string name;
        uint256 balance;
        address add;
    }

    uint256 public numUsers = 0;
    mapping(uint256 => user) public Users;
    mapping(address => bool) public CheckUsers;

    // modifier to ensure a function can only be called by a registered user of the platform    
    modifier userOnly(uint256 id) {
        require(Users[id].add == msg.sender);
        _;
    }

    // modifier to check if a user is a valid user based on id
    modifier validUserId(uint256 id) {
        require(id < numUsers);
        _;
    }

    // initialise the CRO token with specific rates
    function initializeCro(uint256 x, uint256 y) public returns (uint256) {
        croRate = DSMath.wdiv(x,y)/10**16;
        emit initializeCroRate(croRate);
        return croRate;
    }

    // initialise the SHIB token with specific rates
    function initializeShib(uint256 x, uint256 y) public returns (uint256) {
        shibRate = DSMath.wdiv(x,y)/10**16;
        emit initializeShibRate(shibRate);
        return shibRate;
    }

    // initialise the UNI token with specific rates
    function initializeUni(uint256 x, uint256 y) public returns (uint256) {
        uniRate = DSMath.wdiv(x,y)/10**16;
        emit initializeUniRate(uniRate);
        return uniRate;
    }

    // Register a user into the platform by creating a struct User
    function register(string memory name) public payable returns(uint256){
        require(msg.value >= 0.01 ether, "at least 0.01 ETH is needed to register");

        user memory newUser = user(
            name,
            msg.value,
            msg.sender
        );

        uint256 newUserId = numUsers++;
        Users[newUserId] = newUser; 
        CheckUsers[msg.sender] = true;
        emit registerUser(newUserId);
        return newUserId;   

    }

    // Check if user is registered 
    function checkUser(address add) public view returns(bool){
        return CheckUsers[add];
    }

    // Check the balance of a user when given the id
    function checkBalance(uint256 id) public view validUserId(id) returns(uint256){
        return Users[id].balance;
    }

    // Deposit ETH into the platform 
    function deposit(uint256 id)  public payable userOnly(id){
        require(msg.value > 0 ether, "Cannot deposit 0 ETH");
        Users[id].balance += msg.value;
    }

    //Withdraw ETH from the platform 
    function withdraw(uint256 id, uint256 amt) public userOnly(id){
        require(amt > 0 , "Cannot withdraw 0 ETH");
        require(amt >= Users[id].balance);
        Users[id].balance -= amt;
        address payable recipient = payable(msg.sender);
        recipient.transfer(amt);
    }

    // Convert user's balance to CRO
    function convertToCRO(uint256 id,uint256 amt) public {
        require(Users[id].balance >= amt/100,"You don't have enough ETH");
        cro.getToken(amt);
        Users[id].balance -= amt/100;
    }

    // Convert user's balance to SHIB
    function convertToSHIB(uint256 id,uint256 amt) public {
        require(Users[id].balance >= amt/10000,"You don't have enough ETH");
        shib.getToken(amt);
        Users[id].balance -= amt/10000;
    }

    // Convert user's balance to UNI
    function convertToUNI(uint256 id,uint256 amt) public {
        require(Users[id].balance >= amt/10,"You don't have enough ETH");
        uni.getToken(amt);
        Users[id].balance -= amt/10;
    }

    // Convert any supported currency back to ETH
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

    // Returns the percentage of overcollaterization  
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

    // returns the CRO interest rate
    function getCroRate() public view returns(uint256) {
        return croRate;
    }

    // returns the SHIB interest rate
    function getShibRate() public view returns(uint256) {
        return shibRate;
    }

    // returns the UNI interest rate
    function getUniRate() public view returns(uint256) {
        return uniRate;
    }

}

