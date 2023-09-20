// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "forge-std/Test.sol" ;
import "src/PrivacyProxy.sol";
import { Currency, CurrencyLibrary } from "@uniswap/v4-core/contracts/types/Currency.sol";
import {Tornado, IVerifier} from "lib/tornado-core/contracts/Tornado.sol";
import {IHasher} from "lib/tornado-core/contracts/MerkleTreeWithHistory.sol";
import { IPoolManager, PoolKey } from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import { Currency, CurrencyLibrary } from "@uniswap/v4-core/contracts/types/Currency.sol";
import { IERC20Minimal } from "@uniswap/v4-core/contracts/interfaces/external/IERC20Minimal.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";
import {Tornado, IVerifier} from "lib/tornado-core/contracts/Tornado.sol";
import {IHasher} from "lib/tornado-core/contracts/MerkleTreeWithHistory.sol";
import {HookTest} from "./utils/HookTest.sol";
import {GasSnapshot} from "forge-gas-snapshot/GasSnapshot.sol";
import {IHooks} from "@uniswap/v4-core/contracts/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {TickMath} from "@uniswap/v4-core/contracts/libraries/TickMath.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {Deployers} from "@uniswap/v4-core/test/foundry-tests/utils/Deployers.sol";
import {PrivacyHook} from "src/PrivacyHook.sol";

contract PrivacyProxyTest is HookTest, Deployers, GasSnapshot {
    PrivacyProxy public proxy;

    PrivacyHook public privacyHook;

    //Tornado Cash
    IVerifier public immutable verifier;
    IHasher public immutable hasher;
    uint256 public denomination2;

    //Uniswap
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    PoolKey poolKey;
    PoolId poolId;

    function setUp() public {
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
        bytes32 commitment = "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef";
        proxy.deposit(commitment, token0, token1, proxy.denomination, proxy.denomination2);
    }

}
