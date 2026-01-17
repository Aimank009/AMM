// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./interfaces/IAMM.sol";
import "./events/AMMEvents.sol";

contract AMM is ERC20, IAMM, ReentrancyGuard, AMMEvents {
    IERC20 public tokenA;
    IERC20 public tokenB;
    uint256 public reserveA;
    uint256 public reserveB;

    uint256 public constant MINIMUM_LIQUIDITY = 1000;

    error InsufficientLiquidity();
    error InsufficientAmount();
    error InsufficientOutputAmount();
    error InvalidToken();
    error TransferFailed();
    error SlippageExceeded();
    error ZeroAddress();

    constructor(
        address _tokenA,
        address _tokenB
    ) ERC20("AMM LP Token", "AMM-LP") {
        if (_tokenA == address(0)) revert InvalidToken();
        if (_tokenB == address(0)) revert InvalidToken();
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }
}
