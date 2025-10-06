//SPDX-License-Identifier:MIT
pragma solidity ^0.8.24; 

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {ModifyLiquidityParams, SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol"; 
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol"; 
import {BaseHook} from 'v4-periphery/src/utils/BaseHook.sol';
import {IMsgSender} from 'v4-periphery/src/interfaces/IMsgSender.sol'; 
import {ProtocolToken} from "./ProtocolToken.sol";
import {RewardsToken} from "./RewardsToken.sol";
import {RewardsDistributor} from "./RewardsDistributor.sol"; 
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol"; 

contract Hook is BaseHook, Ownable {

    error NotEth(address currency0, address curency1); 
    error NotTheProtocolToken(address currency0, address currency1); 

    IPoolManager public immutable POOL_MANAGER; 
    RewardsToken public rewardsToken;
    ProtocolToken public protocolToken;
    RewardsDistributor public rewardsDistributor;

	constructor(IPoolManager _poolManager, address _rewardsToken, address _rewardsDistributor, address _protocolToken) BaseHook(_poolManager) Ownable(msg.sender){
		POOL_MANAGER = _poolManager; 
        rewardsToken = RewardsToken(_rewardsToken); 
        protocolToken = ProtocolToken(_protocolToken); 
        rewardsDistributor = RewardsDistributor(_rewardsDistributor); 

	}

	function getHookPermissions() public pure override returns(Hooks.Permissions memory){
		return Hooks.Permissions({
			beforeInitialize: true,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: false,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
		});
	}

    function setRewardsToken(address _newRewardsToken) public onlyOwner() {
        rewardsToken = RewardsToken(_newRewardsToken); 
    }

    function setProtocolToken(address _newProtocolToken) public onlyOwner() {
        protocolToken = ProtocolToken(_newProtocolToken); 
    }

    function setRewardsDistributor(address _newRewardsDistributor) public onlyOwner() {
        rewardsDistributor = RewardsDistributor(_newRewardsDistributor); 
    }


    function _beforeInitialize(
        address sender, 
        PoolKey calldata key, 
        uint160 sqrtPriceX96
    ) internal override returns(bytes4) {
        //Check that the pool contains the protocol token
        if (Currency.unwrap(key.currency0) != address(protocolToken) && Currency.unwrap(key.currency1) != address(protocolToken)) {
                revert NotTheProtocolToken(Currency.unwrap(key.currency0), Currency.unwrap(key.currency1)); 
        }

        //Check that the pool contains eth
        if (Currency.unwrap(key.currency0) != address(0) && Currency.unwrap(key.currency1) != address(0)) {
            revert NotEth(Currency.unwrap(key.currency0), Currency.unwrap(key.currency1)); 
        }

        return BaseHook.beforeInitialize.selector;    
        }

    
    //After every swap from ETH to Protocol token, users get funded with some rewards tokens, proportionally to the amount traded 
    function _afterSwap(
        address sender, 
        PoolKey calldata key, 
        SwapParams calldata params, 
        BalanceDelta delta, 
        bytes calldata hookData
    ) internal override returns (bytes4, int128) {

        uint256 ethAmount; 

        if(params.zeroForOne) {
            if(key.currency0 == Currency.wrap(address(0))) {
                int128 amount0 = BalanceDeltaLibrary.amount0(delta); 
                ethAmount = amount0 >= 0 ? uint256(uint128(amount0)) : uint256(uint128(-amount0)); 
            }
        } else {
            if(key.currency1 == Currency.wrap(address(0))) {
                int128 amount1 = BalanceDeltaLibrary.amount1(delta);
                ethAmount = amount1 >= 0 ? uint256(uint128(amount1)) : uint256(uint128(-amount1));
            }
        }

        if(ethAmount == 0) {
            return (BaseHook.afterSwap.selector, 0); 
        }

        address user = IMsgSender(sender).msgSender(); 

        rewardsDistributor.distributeRewards(user, ethAmount);

        return (BaseHook.afterSwap.selector, 0); 
    }

	
}