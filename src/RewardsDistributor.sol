//SPDX-License-Identifier:MIT
pragma solidity ^0.8.24; 

import {RewardsToken} from "./RewardsToken.sol";
import {Hook} from "./Hook.sol"; 
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol"; 


contract RewardsDistributor is Ownable {

	event RewardsDistributed(address to, uint256 amount); 

	error NotTheHook(address sender); 

	RewardsToken public rewardsToken; 
	Hook public hook;  

	constructor() Ownable(msg.sender) {}

	modifier onlyHook() {
		if(msg.sender != address(hook)){
			revert NotTheHook(msg.sender); 
		}
		_; 
	}

	function setRewardsToken(address _rewardsToken) external onlyOwner() {
		rewardsToken = RewardsToken(_rewardsToken); 
	}
	
	function setHook(address _newHook) external onlyOwner() {
		hook = Hook(_newHook); 
	}
	//1 ETH = 1 reward token
	function distributeRewards(address to, uint256 amount) external onlyHook() {
		rewardsToken.mint(to, amount);
		emit RewardsDistributed(to, amount);
	}
	

}