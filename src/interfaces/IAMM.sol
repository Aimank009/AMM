// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAMM {
    function addLiquidity(
        uint256 _amountTokenA,
        uint256 _amountTokenB,
        uint256 _minLPTokenReceived
    ) external returns (uint256);
    function removeLiquidity(
        uint256 _LPTokenToBurn,
        uint256 _minTokenAOut,
        uint256 _minTokenBOut
    ) external returns (uint256, uint256);
    function swapAForB(
        uint256 _amountIn,
        uint256 _minAmountOut
    ) external returns (uint256);
    function swapBForA(
        uint256 _amountIn,
        uint256 _minAmountOut
    ) external returns (uint256);
    function getReserves() external view returns (uint256, uint256);
    function getAmountOut(
        uint256 _amountIn,
        uint256 reserveIn,
        uint256 _reserveOut
    ) external pure returns (uint256);
}
