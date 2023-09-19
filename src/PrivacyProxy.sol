pragma solidity ^0.8.20;
import {Tornado, IVerifier} from "lib/tornado-core/contracts/Tornado.sol";
import {IHasher} from "lib/tornado-core/contracts/MerkleTreeWithHistory.sol";
import { IPoolManager, PoolKey } from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import { Currency, CurrencyLibrary } from "@uniswap/v4-core/contracts/types/Currency.sol";
import { IERC20Minimal } from "@uniswap/v4-core/contracts/interfaces/external/IERC20Minimal.sol";

contract PrivacyProxy is Tornado {

    struct TokenDeposit {
        Currency token1;
        Currency token2;
    }

    IPoolManager poolManager;
    PoolKey poolKey;
    uint256 public denomination2;


    mapping(Currency => uint256) public tokenBalances;

     event DepositTokens(bytes32 indexed commitment,
                    uint32 leafIndex, 
                    uint256 timestamp, 
                    Currency token1, 
                    Currency token2, 
                    PoolKey pool);

    event WithdrawalTokens(address to,
                    bytes32 nullifierHash, 
                    address indexed relayer, 
                    uint256 fee);


    constructor(
        IPoolManager _poolManager,
        PoolKey memory _poolKey,
        IVerifier _verifier,
        IHasher _hasher,
        uint256 _denomination,
        uint32 _merkleTreeHeight,
        uint256 _denomination2
    ) Tornado(_verifier, _hasher, _denomination, _merkleTreeHeight) {
        poolManager = _poolManager;
        poolKey = _poolKey;
        denomination2 = _denomination2;
    }

function deposit(bytes32 _commitment, 
                Currency token1, 
                Currency token2, 
                uint256 _denomination, 
                uint256 _denomination2) external nonReentrant {
    require(!commitments[_commitment], "The commitment has been submitted");
    require(_denomination == denomination, "Incorrect deposit amount for token 1");
    require(_denomination2 == denomination2, "Incorrect deposit amount for token 2");

    uint32 insertedIndex = _insert(_commitment);
    commitments[_commitment] = true;              

    _processDeposit();

    IERC20Minimal(Currency.unwrap(token1)).allowance(msg.sender, address(this));
    IERC20Minimal(Currency.unwrap(token2)).allowance(msg.sender, address(this));
    IERC20Minimal(Currency.unwrap(token1)).approve(address(this), _denomination);
    IERC20Minimal(Currency.unwrap(token2)).approve(address(this), _denomination2);

    tokenBalances[token1] += _denomination;
    tokenBalances[token2] += _denomination2;

    IERC20Minimal(Currency.unwrap(token1)).transfer(address(this), _denomination);
    IERC20Minimal(Currency.unwrap(token2)).transfer(address(this), _denomination2);

    depositIntoPool(_commitment, insertedIndex, block.timestamp, token1, token2, _denomination, _denomination2);
}

  function depositIntoPool(bytes32 _commitment, 
                           uint32 insertedIndex, 
                           uint256 timestamp,
                           Currency token1, 
                           Currency token2, 
                           uint256 _denomination, 
                           uint256 _denomination2) internal { 
        poolManager.donate(poolKey, _denomination, _denomination2, "");
        tokenBalances[token1] -= _denomination;
        tokenBalances[token2] -= _denomination2;
        emit DepositTokens(_commitment, insertedIndex, timestamp, token1, token2, poolKey);
  }

    function _processDeposit() internal override {

    }

    function _processWithdraw(
        address payable _recipient,
        address payable _relayer,
        uint256 _fee,
        uint256 _refund
    ) internal override {
    }

}