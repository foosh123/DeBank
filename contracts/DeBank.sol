pragma solidity >= 0.5.0;

contract DeBank{

    Cro cro = new Cro();
    Shib shib = new Shib();
    Uni uni = new Uni();

    struct user{
        string name;
        uint256 balance;
        address add;
    }

    event Withdraw(string choiceOfCurrency, uint256 amount);

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
        msg.sender.transfer(amt);
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

    function convertBackToETH(string memory choiceOfCurrency, uint256 id, uint256 amt) public {
        if(keccak256(abi.encodePacked(choiceOfCurrency))==keccak256(abi.encodePacked("Cro")) ) {
            require(cro.checkBalance() >= amt, "You dont have enough CRO");
            cro.sendToken(msg.sender,address(this),amt);
            Users[id].balance += amt/100;
            emit Withdraw(choiceOfCurrency, amt);
        } else if(keccak256(abi.encodePacked(choiceOfCurrency))==keccak256(abi.encodePacked("Shib")) ) {
            require(shib.checkBalance() >= amt, "You dont have enough SHIB");
            shib.sendToken(msg.sender,address(this), amt);
            Users[id].balance += amt/10000;
            emit Withdraw(choiceOfCurrency, amt);
        } else if(keccak256(abi.encodePacked(choiceOfCurrency))==keccak256(abi.encodePacked("Uni")) ) {
            require(uni.checkBalance() >= amt, "You dont have enough UNI");
            uni.sendToken(msg.sender, address(this), amt);
            Users[id].balance += amt/10;
            emit Withdraw(choiceOfCurrency, amt);
        } 
    }

}