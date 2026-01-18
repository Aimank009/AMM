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

    function getReserves() external view override returns (uint256, uint256) {
        return (reserveA, reserveB);
    }

    function getAmountOut(
        uint256 _amountIn,
        uint256 _reserveIn,
        uint256 _reserveOut
    ) external pure override returns (uint256) {
        if (_amountIn == 0) revert InsufficientAmount();
        if (_reserveIn == 0 || _reserveOut == 0) revert InsufficientLiquidity();

        uint256 amountInWithFee = _amountIn * 997;
        uint256 numerator = amountInWithFee * _reserveOut;
        uint256 denominator = (_reserveIn * 1000) + amountInWithFee;

        uint256 amountOut = numerator / denominator;

        return amountOut;
    }

    function sqrt(uint256 _y) internal pure returns (uint256 z) {
        if (_y > 3) {
            z = _y;
            uint256 x = _y / 2 + 1;
            while (x < z) {
                z = x;
                x = (_y / x + x) / 2;
            }
        } else if (_y != 0) {
            z = 1;
        }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function addLiquidity(
        uint256 _amountTokenA,
        uint256 _amountTokenB,
        uint256 _minLPTokenReceived
    ) external override nonReentrant returns (uint256) {
        if (_amountTokenA == 0 || _amountTokenB == 0)
            revert InsufficientAmount();

        bool successA = tokenA.transferFrom(
            msg.sender,
            address(this),
            _amountTokenA
        );
        if (!successA) revert TransferFailed();
        bool successB = tokenB.transferFrom(
            msg.sender,
            address(this),
            _amountTokenB
        );
        if (!successB) revert TransferFailed();

        uint256 _totalSupply = totalSupply();

        uint256 lpTokens;

        if (_totalSupply == 0) {
            lpTokens = sqrt(_amountTokenA * _amountTokenB) - MINIMUM_LIQUIDITY;
            _mint(address(1), MINIMUM_LIQUIDITY);
        } else {
            lpTokens = min(
                (_amountTokenA * _totalSupply) / reserveA,
                (_amountTokenB * _totalSupply) / reserveB
            );
        }
        if (lpTokens < _minLPTokenReceived) revert SlippageExceeded();
        _mint(msg.sender, lpTokens);

        reserveA += _amountTokenA;
        reserveB += _amountTokenB;

        emit LiquidityAdded(msg.sender, _amountTokenA, _amountTokenB, lpTokens);
        emit Sync(reserveA, reserveB);

        return lpTokens;
    }
    function removeLiquidity(
        uint256 _LPTokenToBurn,
        uint256 _minTokenAOut,
        uint256 _minTokenBOut
    ) external override nonReentrant returns (uint256, uint256) {
        if (_LPTokenToBurn == 0) revert InvalidToken();

        uint256 _totalSupply = totalSupply();

        uint256 amountA = (_LPTokenToBurn * reserveA) / _totalSupply;
        uint256 amountB = (_LPTokenToBurn * reserveB) / _totalSupply;

        if (amountA < _minTokenAOut) revert SlippageExceeded();
        if (amountB < _minTokenBOut) revert SlippageExceeded();

        _burn(msg.sender, _LPTokenToBurn);

        reserveA -= amountA;
        reserveB -= amountB;

        bool successA = tokenA.transfer(msg.sender, amountA);
        if (!successA) revert TransferFailed();
        bool successB = tokenB.transfer(msg.sender, amountB);
        if (!successB) revert TransferFailed();

        emit LiquidityRemoved(msg.sender, amountA, amountB, _LPTokenToBurn);
        emit Sync(reserveA, reserveB);

        return (amountA, amountB);
    }

    function swapAForB(
        uint256 _amountIn,
        uint256 _minAmountOut
    ) external override nonReentrant returns (uint256) {
        if (_amountIn == 0) revert InsufficientAmount();

        uint256 _amountOut = this.getAmountOut(_amountIn, reserveA, reserveB);

        if (_amountOut < _minAmountOut) revert SlippageExceeded();

        bool successTransferA = tokenA.transferFrom(
            msg.sender,
            address(this),
            _amountIn
        );
        if (!successTransferA) revert TransferFailed();
        bool successTransferB = tokenB.transfer(msg.sender, _amountOut);
        if (!successTransferB) revert TransferFailed();

        reserveA += _amountIn;
        reserveB -= _amountOut;

        emit Swap(msg.sender, address(tokenA), _amountIn, _amountOut);
        emit Sync(reserveA, reserveB);

        return (_amountOut);
    }
}
