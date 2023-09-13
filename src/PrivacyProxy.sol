


contract PrivacyProxy {

    address public poolManager;
    

    constructor(address _poolManager) public {
        poolManager = _poolManager;
    }

    event Deposit(address indexed token1, address indexed token2, uint256 amount1, uint256 amount2);
    event Withdrawal(address indexed token1, address indexed token2, uint256 amount1, uint256 amount2);

    function makeDeposit(address token1, address token2) public payable {

    }

    function makeWithdrawal(address token1, address token2) public payable {

    }



}