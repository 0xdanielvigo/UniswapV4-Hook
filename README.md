# Uniswap V4 Hook for Reward Distribution

This project implements a custom Uniswap V4 hook that rewards users who trade tokens from ETH to the protocol token. The rewards are distributed in the form of a dedicated rewards token, incentivizing users to participate in the protocol.

## Features

- **Custom Hook Integration**: Leverages Uniswap V4's hook functionality to execute custom logic during swaps.
- **Reward Distribution**: Automatically assigns rewards to users based on the amount of ETH traded for the protocol token.
- **Protocol Token Support**: Ensures trades involve the designated protocol token and ETH.

## Components

- **`Hook.sol`**: Implements the custom Uniswap V4 hook logic, including reward distribution after swaps.
- **`RewardsDistributor.sol`**: Manages the distribution of rewards tokens to users.
- **`RewardsToken.sol`**: The ERC-20 token used as the reward currency.
- **`ProtocolToken.sol`**: The designated protocol token involved in trades.

## How It Works

1. **Pool Creation**: A Uniswap V4 pool is created with ETH and the protocol token.
2. **Swap Monitoring**: The custom hook monitors swaps in the pool.
3. **Reward Assignment**: After each swap from ETH to the protocol token, the user is rewarded with a proportional amount of rewards tokens.
4. **Reward Distribution**: The `RewardsDistributor` contract handles the minting and distribution of rewards tokens.

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/your-repo/uniswapv4-hook.git
   cd uniswapv4-hook

2. Install dependencies
	```bash
	forge install

3. Run tests
	```bash
	forge test
