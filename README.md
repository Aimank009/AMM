# Automated Market Maker (AMM)

A decentralized exchange smart contract implementing the constant product formula (x \* y = k) for token swaps, built with Solidity and Foundry.

## Overview

This AMM allows users to:

- Provide liquidity and earn swap fees
- Swap between two ERC20 tokens
- Remove liquidity at any time

The contract uses the Uniswap V2 style constant product formula with a 0.3% swap fee.

## Features

### Core Functionality

- **Constant Product Formula**: Uses x \* y = k to determine swap prices automatically
- **Liquidity Provision**: Users deposit token pairs and receive LP tokens
- **Token Swaps**: Swap Token A for Token B or vice versa
- **Liquidity Removal**: Burn LP tokens to withdraw proportional share of pool

### Security Features

- **Slippage Protection**: All functions accept minimum output parameters
- **Reentrancy Guard**: Protected against reentrancy attacks
- **K Invariant Check**: Verifies pool integrity after every swap
- **Minimum Liquidity Lock**: 1000 LP tokens locked forever to prevent share inflation attacks
- **Custom Errors**: Gas-efficient error handling

### Fee Mechanism

- 0.3% fee on all swaps
- Fees remain in the pool
- LPs earn fees proportional to their share

## Contract Architecture

```
AMM/
├── src/
│   ├── interfaces/
│   │   └── IAMM.sol
│   ├── events/
│   │   └── AMMEvents.sol
│   └── AMM.sol
└── test/
    └── AMM.t.sol
```

## Technical Specifications

### State Variables

| Variable          | Type    | Description              |
| ----------------- | ------- | ------------------------ |
| tokenA            | IERC20  | First token in the pair  |
| tokenB            | IERC20  | Second token in the pair |
| reserveA          | uint256 | Amount of tokenA in pool |
| reserveB          | uint256 | Amount of tokenB in pool |
| MINIMUM_LIQUIDITY | uint256 | 1000 (locked forever)    |

### Custom Errors

| Error                    | Description                        |
| ------------------------ | ---------------------------------- |
| InsufficientLiquidity    | Pool has zero reserves             |
| InsufficientAmount       | Input amount is zero               |
| InsufficientOutputAmount | Output is zero                     |
| InvalidToken             | Token address is zero              |
| TransferFailed           | ERC20 transfer failed              |
| SlippageExceeded         | Output less than minimum specified |
| ZeroAddress              | Address is zero                    |
| KInvariantViolation      | Pool integrity check failed        |

### Functions

#### View Functions

**getReserves()**

```solidity
function getReserves() external view returns (uint256, uint256)
```

Returns current reserves of both tokens.

**getAmountOut()**

```solidity
function getAmountOut(
    uint256 _amountIn,
    uint256 _reserveIn,
    uint256 _reserveOut
) external pure returns (uint256)
```

Calculates output amount for a given input using the constant product formula with 0.3% fee.

Formula:

```
amountInWithFee = amountIn * 997
numerator = amountInWithFee * reserveOut
denominator = (reserveIn * 1000) + amountInWithFee
amountOut = numerator / denominator
```

#### Liquidity Functions

**addLiquidity()**

```solidity
function addLiquidity(
    uint256 _amountTokenA,
    uint256 _amountTokenB,
    uint256 _minLPTokenReceived
) external returns (uint256)
```

Deposits tokens and mints LP tokens.

LP Token Calculation:

- First deposit: `sqrt(amountA * amountB) - MINIMUM_LIQUIDITY`
- Subsequent: `min((amountA * totalSupply) / reserveA, (amountB * totalSupply) / reserveB)`

**removeLiquidity()**

```solidity
function removeLiquidity(
    uint256 _lpTokens,
    uint256 _minAmountA,
    uint256 _minAmountB
) external returns (uint256, uint256)
```

Burns LP tokens and returns proportional share of both tokens.

Withdrawal Calculation:

```
amountA = (lpTokens * reserveA) / totalSupply
amountB = (lpTokens * reserveB) / totalSupply
```

#### Swap Functions

**swapAForB()**

```solidity
function swapAForB(
    uint256 _amountIn,
    uint256 _minAmountOut
) external returns (uint256)
```

Swaps Token A for Token B.

**swapBForA()**

```solidity
function swapBForA(
    uint256 _amountIn,
    uint256 _minAmountOut
) external returns (uint256)
```

Swaps Token B for Token A.

### Events

| Event            | Parameters                                | Description                       |
| ---------------- | ----------------------------------------- | --------------------------------- |
| LiquidityAdded   | provider, amountA, amountB, lpTokenMinted | Emitted when liquidity is added   |
| LiquidityRemoved | provider, amountA, amountB, lpTokenBurned | Emitted when liquidity is removed |
| Swap             | user, tokenIn, amountIn, amountOut        | Emitted on every swap             |
| Sync             | reserveA, reserveB                        | Emitted when reserves are updated |

## Mathematical Concepts

### Constant Product Formula

The AMM maintains the invariant:

```
x * y = k
```

Where:

- x = reserve of Token A
- y = reserve of Token B
- k = constant product (increases with fees)

### Price Determination

Spot price is derived from the ratio of reserves:

```
Price of A in terms of B = reserveB / reserveA
```

### Price Impact

Larger trades have more price impact due to the hyperbolic curve of x \* y = k.

### Impermanent Loss

LPs may experience impermanent loss when token prices diverge from the initial ratio.

## Installation

```bash
git clone https://github.com/Aimank009/AMM.git
cd AMM
forge install
```

## Usage

### Build

```bash
forge build
```

### Test

```bash
forge test
```

### Deploy

```bash
forge script script/Deploy.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY>
```

## Test Coverage

The test suite includes 20 tests covering:

- Add liquidity (first and subsequent deposits)
- Remove liquidity
- Swap A for B
- Swap B for A
- Get amount out calculation
- Get reserves
- Fee collection verification
- Minimum liquidity lock
- Slippage protection
- Zero amount reverts
- Zero address reverts

## Dependencies

- OpenZeppelin Contracts v5.0
  - ERC20
  - IERC20
  - ReentrancyGuard
- Foundry (forge-std)

## Security Considerations

1. **Reentrancy**: Protected by OpenZeppelin ReentrancyGuard
2. **Slippage**: All functions accept minimum output parameters
3. **Front-running**: Users should set appropriate slippage tolerance
4. **Flash Loan Attacks**: K invariant check prevents manipulation
5. **First Depositor Attack**: Minimum liquidity lock prevents share inflation

## License

MIT
