//SPDX-License-Identifier:MIT
pragma solidity ^0.8.24; 

import {Test, console} from "forge-std/Test.sol"; 
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {ModifyLiquidityParams, SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol"; 
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol"; 
import {BaseHook} from 'v4-periphery/src/utils/BaseHook.sol';
import {IMsgSender} from 'v4-periphery/src/interfaces/IMsgSender.sol'; 
import {ProtocolToken} from "../src/ProtocolToken.sol";
import {RewardsToken} from "../src/RewardsToken.sol";
import {RewardsDistributor} from "../src/RewardsDistributor.sol"; 
import {Hook} from "../src/Hook.sol";
import {HookMiner} from 'v4-periphery/src/utils/HookMiner.sol';

contract HookTest is Test {

Hook public hook;
RewardsDistributor public rewardsDistributor;
RewardsToken public rewardsToken;
ProtocolToken public protocolToken;
IPoolManager public poolManager = IPoolManager(0x360E68faCcca8cA495c1B759Fd9EEe466db9FB32); 

address admin = makeAddr("admin");

function setUp() public {
	
	vm.startPrank(admin);
	protocolToken = new ProtocolToken("Protocol token", "PTC"); 
	rewardsDistributor = new RewardsDistributor(); 
	rewardsToken = new RewardsToken("Rewards Token", "RWT", address(rewardsDistributor)); 
	_createHook();
	vm.stopPrank(); 

}

function _createHook() internal {
	address deployer = admin; 
	uint160 flags = uint160(Hooks.BEFORE_INITIALIZE_FLAG | Hooks.AFTER_SWAP_FLAG); 
	bytes memory creationCode = type(Hook).creationCode;
	bytes memory constructorArgs = abi.encode(poolManager, address(rewardsToken), address(rewardsDistributor), address(protocolToken)); 

	(address _hook, ) = HookMiner.find(deployer, flags, creationCode, constructorArgs);
	hook = Hook(_hook);
}
}