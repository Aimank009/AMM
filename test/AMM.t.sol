// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AMM.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000000 * 10 ** 18);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract AMMTest is Test {
    AMM public amm;
    MockToken public tokenA;
    MockToken public tokenB;

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    uint256 public constant INITIAL_BALANCE = 100000 * 10 ** 18;

    function setUp() public {
        tokenA = new MockToken("Token A", "TKA");
        tokenB = new MockToken("Token B", "TKB");
        amm = new AMM(address(tokenA), address(tokenB));

        tokenA.mint(alice, INITIAL_BALANCE);
        tokenB.mint(alice, INITIAL_BALANCE);
        tokenA.mint(bob, INITIAL_BALANCE);
        tokenB.mint(bob, INITIAL_BALANCE);

        vm.startPrank(alice);
        tokenA.approve(address(amm), type(uint256).max);
        tokenB.approve(address(amm), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(bob);
        tokenA.approve(address(amm), type(uint256).max);
        tokenB.approve(address(amm), type(uint256).max);
        vm.stopPrank();
    }

    function test_AddLiquidity_FirstDeposit() public {
        vm.startPrank(alice);
        uint256 amountA = 1000 * 10 ** 18;
        uint256 amountB = 2000 * 10 ** 18;

        uint256 lpTokens = amm.addLiquidity(amountA, amountB, 0);

        assertGt(lpTokens, 0);
        assertEq(amm.balanceOf(alice), lpTokens);

        (uint256 reserveA, uint256 reserveB) = amm.getReserves();
        assertEq(reserveA, amountA);
        assertEq(reserveB, amountB);
        vm.stopPrank();
    }

    function test_AddLiquidity_SubsequentDeposit() public {
        vm.startPrank(alice);
        amm.addLiquidity(1000 * 10 ** 18, 2000 * 10 ** 18, 0);
        vm.stopPrank();

        vm.startPrank(bob);
        uint256 lpBefore = amm.balanceOf(bob);
        uint256 lpTokens = amm.addLiquidity(500 * 10 ** 18, 1000 * 10 ** 18, 0);

        assertGt(lpTokens, 0);
        assertEq(amm.balanceOf(bob), lpBefore + lpTokens);
        vm.stopPrank();
    }

    function test_AddLiquidity_RevertOnZeroAmount() public {
        vm.startPrank(alice);
        vm.expectRevert(AMM.InsufficientAmount.selector);
        amm.addLiquidity(0, 1000, 0);
        vm.stopPrank();
    }

    function test_AddLiquidity_RevertOnSlippage() public {
        vm.startPrank(alice);
        vm.expectRevert(AMM.SlippageExceeded.selector);
        amm.addLiquidity(1000 * 10 ** 18, 2000 * 10 ** 18, type(uint256).max);
        vm.stopPrank();
    }

    function test_RemoveLiquidity() public {
        vm.startPrank(alice);
        uint256 lpTokens = amm.addLiquidity(
            1000 * 10 ** 18,
            2000 * 10 ** 18,
            0
        );

        uint256 tokenABefore = tokenA.balanceOf(alice);
        uint256 tokenBBefore = tokenB.balanceOf(alice);

        (uint256 amountA, uint256 amountB) = amm.removeLiquidity(
            lpTokens,
            0,
            0
        );

        assertGt(amountA, 0);
        assertGt(amountB, 0);
        assertEq(tokenA.balanceOf(alice), tokenABefore + amountA);
        assertEq(tokenB.balanceOf(alice), tokenBBefore + amountB);
        assertEq(amm.balanceOf(alice), 0);
        vm.stopPrank();
    }

    function test_RemoveLiquidity_RevertOnZeroLP() public {
        vm.startPrank(alice);
        amm.addLiquidity(1000 * 10 ** 18, 2000 * 10 ** 18, 0);

        vm.expectRevert(AMM.InvalidToken.selector);
        amm.removeLiquidity(0, 0, 0);
        vm.stopPrank();
    }

    function test_RemoveLiquidity_RevertOnSlippage() public {
        vm.startPrank(alice);
        uint256 lpTokens = amm.addLiquidity(
            1000 * 10 ** 18,
            2000 * 10 ** 18,
            0
        );

        vm.expectRevert(AMM.SlippageExceeded.selector);
        amm.removeLiquidity(lpTokens, type(uint256).max, 0);
        vm.stopPrank();
    }

    function test_SwapAForB() public {
        vm.startPrank(alice);
        amm.addLiquidity(1000 * 10 ** 18, 2000 * 10 ** 18, 0);
        vm.stopPrank();

        vm.startPrank(bob);
        uint256 amountIn = 100 * 10 ** 18;
        uint256 tokenBBefore = tokenB.balanceOf(bob);

        uint256 amountOut = amm.swapAForB(amountIn, 0);

        assertGt(amountOut, 0);
        assertEq(tokenB.balanceOf(bob), tokenBBefore + amountOut);
        vm.stopPrank();
    }

    function test_SwapAForB_RevertOnZeroAmount() public {
        vm.startPrank(alice);
        amm.addLiquidity(1000 * 10 ** 18, 2000 * 10 ** 18, 0);

        vm.expectRevert(AMM.InsufficientAmount.selector);
        amm.swapAForB(0, 0);
        vm.stopPrank();
    }

    function test_SwapAForB_RevertOnSlippage() public {
        vm.startPrank(alice);
        amm.addLiquidity(1000 * 10 ** 18, 2000 * 10 ** 18, 0);

        vm.expectRevert(AMM.SlippageExceeded.selector);
        amm.swapAForB(100 * 10 ** 18, type(uint256).max);
        vm.stopPrank();
    }

    function test_SwapBForA() public {
        vm.startPrank(alice);
        amm.addLiquidity(1000 * 10 ** 18, 2000 * 10 ** 18, 0);
        vm.stopPrank();

        vm.startPrank(bob);
        uint256 amountIn = 200 * 10 ** 18;
        uint256 tokenABefore = tokenA.balanceOf(bob);

        uint256 amountOut = amm.swapBForA(amountIn, 0);

        assertGt(amountOut, 0);
        assertEq(tokenA.balanceOf(bob), tokenABefore + amountOut);
        vm.stopPrank();
    }

    function test_SwapBForA_RevertOnZeroAmount() public {
        vm.startPrank(alice);
        amm.addLiquidity(1000 * 10 ** 18, 2000 * 10 ** 18, 0);

        vm.expectRevert(AMM.InsufficientAmount.selector);
        amm.swapBForA(0, 0);
        vm.stopPrank();
    }

    function test_SwapBForA_RevertOnSlippage() public {
        vm.startPrank(alice);
        amm.addLiquidity(1000 * 10 ** 18, 2000 * 10 ** 18, 0);

        vm.expectRevert(AMM.SlippageExceeded.selector);
        amm.swapBForA(200 * 10 ** 18, type(uint256).max);
        vm.stopPrank();
    }

    function test_GetAmountOut() public view {
        uint256 amountIn = 100;
        uint256 reserveIn = 1000;
        uint256 reserveOut = 2000;

        uint256 amountOut = amm.getAmountOut(amountIn, reserveIn, reserveOut);

        assertGt(amountOut, 0);
        assertLt(amountOut, reserveOut);
    }

    function test_GetAmountOut_RevertOnZeroInput() public {
        vm.expectRevert(AMM.InsufficientAmount.selector);
        amm.getAmountOut(0, 1000, 2000);
    }

    function test_GetAmountOut_RevertOnZeroReserve() public {
        vm.expectRevert(AMM.InsufficientLiquidity.selector);
        amm.getAmountOut(100, 0, 2000);
    }

    function test_GetReserves() public {
        vm.startPrank(alice);
        amm.addLiquidity(1000 * 10 ** 18, 2000 * 10 ** 18, 0);
        vm.stopPrank();

        (uint256 reserveA, uint256 reserveB) = amm.getReserves();
        assertEq(reserveA, 1000 * 10 ** 18);
        assertEq(reserveB, 2000 * 10 ** 18);
    }

    function test_FeeCollection() public {
        vm.startPrank(alice);
        amm.addLiquidity(1000 * 10 ** 18, 2000 * 10 ** 18, 0);
        vm.stopPrank();

        (uint256 reserveABefore, uint256 reserveBBefore) = amm.getReserves();
        uint256 kBefore = reserveABefore * reserveBBefore;

        vm.startPrank(bob);
        amm.swapAForB(100 * 10 ** 18, 0);
        vm.stopPrank();

        (uint256 reserveAAfter, uint256 reserveBAfter) = amm.getReserves();
        uint256 kAfter = reserveAAfter * reserveBAfter;

        assertGe(kAfter, kBefore);
    }

    function test_MinimumLiquidityLock() public {
        vm.startPrank(alice);
        uint256 lpTokens = amm.addLiquidity(
            1000 * 10 ** 18,
            2000 * 10 ** 18,
            0
        );

        uint256 lockedLP = amm.balanceOf(address(1));
        assertEq(lockedLP, 1000);

        uint256 totalSupply = amm.totalSupply();
        assertEq(totalSupply, lpTokens + 1000);
        vm.stopPrank();
    }

    function test_Constructor_RevertOnZeroAddress() public {
        vm.expectRevert(AMM.InvalidToken.selector);
        new AMM(address(0), address(tokenB));

        vm.expectRevert(AMM.InvalidToken.selector);
        new AMM(address(tokenA), address(0));
    }
}
