// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "forge-std/Test.sol";
import "src/PrivacyProxy.sol";
import { Currency, CurrencyLibrary } from "@uniswap/v4-core/contracts/types/Currency.sol";
import { Tornado, IVerifier } from "lib/tornado-core/contracts/Tornado.sol";
import { IHasher } from "lib/tornado-core/contracts/MerkleTreeWithHistory.sol";
import { IPoolManager, PoolKey } from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import { IERC20Minimal } from "@uniswap/v4-core/contracts/interfaces/external/IERC20Minimal.sol";
import { HookTest } from "./utils/HookTest.sol";
import { GasSnapshot } from "forge-gas-snapshot/GasSnapshot.sol";
import { IHooks } from "@uniswap/v4-core/contracts/interfaces/IHooks.sol";
import { PoolId, PoolIdLibrary } from "@uniswap/v4-core/contracts/types/PoolId.sol";
import { Deployers } from "@uniswap/v4-core/test/foundry-tests/utils/Deployers.sol";
import { PrivacyHook } from "src/PrivacyHook.sol";
import { Tornado } from "lib/tornado-core/contracts/Tornado.sol";

contract PrivacyProxyTest is HookTest, Deployers, GasSnapshot {
    PrivacyProxy public proxy;

    PrivacyHook public privacyHook;

    bytes32 public commitment; 

    //Tornado Cash
    IVerifier public immutable verifier;
    IHasher public immutable hasher;
    uint256 public denomination2;

    //Uniswap
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    PoolKey public poolKey;
    PoolId public poolId;

    // Test the constructor to ensure it correctly sets poolManager
    function testConstructorSetsPoolManager() public {
        assertEq(address(privacyProxy.poolManager()), address(poolManager), "Incorrect poolManager");
    }

    // Test the constructor to ensure it correctly sets poolKey
    function testConstructorSetsPoolKey() public {
        assertEq(address(privacyProxy.poolKey()), address(poolKey), "Incorrect poolKey");
    }

    // Test the constructor to ensure it correctly sets denomination and denomination2
    function testConstructorSetsDenominations() public {
        assertEq(privacyProxy.denomination(), 100, "Incorrect denomination");
        assertEq(privacyProxy.denomination2(), 20, "Incorrect denomination2");
    }


    function setUp() public {
        bytes32 secret = 0x7465737473656372657400000000000000000000000000000000000000000000;
        bytes32 nullifier = 0x746573746e756c6c696669657200000000000000000000000000000000000000;
        commitment = keccak256(abi.encodePacked(secret, nullifier));
        // creates the pool manager, test tokens, and other utility routers
        HookTest.initHookTestEnv();

        // Create the pool
        poolKey = PoolKey(Currency.wrap(address(token0)), Currency.wrap(address(token1)), 3000, 60, IHooks(privacyHook));
        poolId = poolKey.toId();
        manager.initialize(poolKey, SQRT_RATIO_1_1, ZERO_BYTES);

        privacyHook = new PrivacyHook(manager);
        proxy = new PrivacyProxy(manager, poolKey, verifier, hasher, 100, 20, 200);
    }

    function testDeposit() public {
        uint256 beforeDepositToken0Reserves = manager.reservesOf(token0);
        uint256 beforeDepositToken1Reserves = manager.reservesOf(token1);
        proxy.deposit(commitment, token0, token1, proxy.denomination, proxy.denomination2);
        assertEq(manager.reservesOf(token0), beforeDepositToken0Reserves + proxy.denomination);
        assertEq(manager.reservesOf(token1), beforeDepositToken1Reserves + proxy.denomination2);
    }

}
