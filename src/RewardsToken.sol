//SPDX-License-Identifier:MIT
pragma solidity ^0.8.24; 

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol"; 
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol"; 

contract RewardsToken is ERC20, Ownable {

	constructor(string memory name, string memory symbol, address rewardsDistributor) 
	ERC20(name, symbol) 
	Ownable(rewardsDistributor)
	{}

	function mint(address to, uint256 amount) public onlyOwner() {
		_mint(to, amount); 
	}
 


}