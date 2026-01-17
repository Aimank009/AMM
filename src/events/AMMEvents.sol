// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract AMMEvents {
    event LiquidityAdded(
        address indexed _provider,
        uint256 _amountA,
        uint256 _amountB,
        uint256 _lpTokenMinted
    );
    event LiquidityRemoved(
        address indexed _provider,
        uint256 _amountA,
        uint256 _amountB,
        uint256 _lpTokenBurned
    );
    event Swap(
        address indexed _swap,
        address indexed _tokenIn,
        uint256 _amountIn,
        uint256 _amountOut
    );
    event Sync(uint256 _reserveA, uint256 _reserveB);
}
