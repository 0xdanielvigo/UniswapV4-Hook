//SPDX-License-Identifier:MIT
pragma solidity ^0.8.24; 

import {Test, console} from "forge-std/Test.sol"; 
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {ModifyLiquidityParams, SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol"; 
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol"; 
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol"; 
import {BaseHook} from 'v4-periphery/src/utils/BaseHook.sol';
import {IMsgSender} from 'v4-periphery/src/interfaces/IMsgSender.sol'; 
import {Actions} from 'v4-periphery/src/libraries/Actions.sol'; 
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {ProtocolToken} from "../src/ProtocolToken.sol";
import {RewardsToken} from "../src/RewardsToken.sol";
import {RewardsDistributor} from "../src/RewardsDistributor.sol"; 
import {Hook} from "../src/Hook.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol"; 
import {HookMiner} from 'v4-periphery/src/utils/HookMiner.sol';
import {IPositionManager} from 'v4-periphery/src/interfaces/IPositionManager.sol';
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol"; 
import {SafeCallback} from 'v4-periphery/src/base/SafeCallback.sol';

contract HookTest is Test {

Hook public hook;
RewardsDistributor public rewardsDistributor;
RewardsToken public rewardsToken;
ProtocolToken public protocolToken;
IPoolManager public poolManager = IPoolManager(0x360E68faCcca8cA495c1B759Fd9EEe466db9FB32); 
IPositionManager public positionManager = IPositionManager(0xd88F38F930b7952f2DB2432Cb002E7abbF3dD869); 
uint256 public action; 
uint256 public ADD_LIQUIDITY = 1; 
uint256 public SWAP = 2;
int256 constant LIQUIDITY_DELTA = 1e12;
uint160 constant MIN_SQRT_PRICE = 4295128739;

function setUp() public {
	protocolToken = new ProtocolToken("Protocol token", "PTC"); 
	rewardsDistributor = new RewardsDistributor(); 
	rewardsToken = new RewardsToken("Rewards Token", "RWT", address(rewardsDistributor)); 
	_createHook();

	rewardsDistributor.setHook(address(hook));
	rewardsDistributor.setRewardsToken(address(rewardsToken));
}

function _createHook() internal {
	address deployer = address(this); 
	uint160 flags = uint160(Hooks.BEFORE_INITIALIZE_FLAG | Hooks.AFTER_SWAP_FLAG); 
	bytes memory creationCode = type(Hook).creationCode;
	bytes memory constructorArgs = abi.encode(poolManager, address(rewardsToken), address(rewardsDistributor), address(protocolToken)); 

	(address _hook, bytes32 salt) = HookMiner.find(deployer, flags, creationCode, constructorArgs);
	hook = new Hook{salt: salt}(poolManager, address(rewardsToken), address(rewardsDistributor), address(protocolToken));
}

function test_rewardsAreDistributed() public {

	_createPool(); 

	_addInitialLiquidity();

	_swap(); 

	_assert(); 
}

function _createPool() internal {
	PoolKey memory key = PoolKey({
		currency0: Currency.wrap(address(0)),
		currency1: Currency.wrap(address(protocolToken)), 
		fee: 3000, 
		tickSpacing: 60, 
		hooks: IHooks(address(hook))
	});
	uint160 sqrtPriceX96 = 7922816251426433759354395033;
	poolManager.initialize(key, sqrtPriceX96); 
}

function _addInitialLiquidity() internal {
	
	deal(address(protocolToken), address(this), 1e6 * 1e18); 
	deal(address(this), 1e6 * 1e18); 

	action = ADD_LIQUIDITY; 
	poolManager.unlock("");
}

function _swap() internal {

	action = SWAP; 
	poolManager.unlock(""); 
}

function _assert() internal {
	
	assertNotEq(rewardsToken.totalSupply(), 0); 
}

function unlockCallback(bytes calldata data) public returns (bytes memory) {
		PoolKey memory key = PoolKey({
		currency0: Currency.wrap(address(0)),
		currency1: Currency.wrap(address(protocolToken)), 
		fee: 3000, 
		tickSpacing: 60, 
		hooks: IHooks(address(hook))
		});
		
		if (action == ADD_LIQUIDITY) {
		(BalanceDelta delta,) = poolManager.modifyLiquidity({
                key: key,
                params: ModifyLiquidityParams({
                    tickLower: TickMath.minUsableTick(60),
                    tickUpper: TickMath.maxUsableTick(60),
                    liquidityDelta: LIQUIDITY_DELTA,
                    salt: bytes32(0)
                }),
                hookData: ""
            });

		if (delta.amount0() < 0) {
                uint256 amount0 = uint128(-delta.amount0());
                poolManager.sync(key.currency0);
                poolManager.settle{value: amount0}();
            }
            if (delta.amount1() < 0) {
                uint256 amount1 = uint128(-delta.amount1());
                poolManager.sync(key.currency1);
                ERC20(protocolToken).transfer(address(poolManager), amount1);
                poolManager.settle();
            }
            return "";
		} if(action == SWAP) {
			uint256 buyingAmount = (protocolToken.balanceOf(address(this)) / 10);
			(BalanceDelta delta ) = poolManager.swap({
				key: key, 
				params: SwapParams({
					zeroForOne: true, 
					amountSpecified: -(int256(buyingAmount)), 
					sqrtPriceLimitX96: MIN_SQRT_PRICE + 1
				}), 
				hookData: ""
			}); 
			int128 amount0 = delta.amount0();
            int128 amount1 = delta.amount1();

			poolManager.take({
				currency: Currency.wrap(address(protocolToken)), 
				to: address(this), 
				amount: uint256(uint128(amount1))
			}); 

			poolManager.sync(key.currency0); 
			poolManager.settle{value: uint256(uint128(-amount0))}(); 
		}
	}	

	function msgSender() public view returns(address){
		return address(this);
	}
}