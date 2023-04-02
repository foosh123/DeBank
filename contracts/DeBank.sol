pragma solidity >= 0.5.0;

contract DeBank{

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
    }

}