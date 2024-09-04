pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/LiquidAX.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("Mock Token", "MOCK") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract LiquidAXTest is Test {
    LiquidAX liquidAX;
    MockERC20 collateralToken;
    LAXDToken laxdToken;

    address user = address(1);
    uint256 constant COLLATERAL_AMOUNT = 1000e18;
    uint256 constant BORROW_AMOUNT = 500e18;

    function setUp() public {
        collateralToken = new MockERC20();
        liquidAX = new LiquidAX(address(collateralToken));
        laxdToken = liquidAX.laxdToken();

        collateralToken.mint(user, COLLATERAL_AMOUNT);
    }

    function testBorrow() public {
        vm.startPrank(user);
        collateralToken.approve(address(liquidAX), COLLATERAL_AMOUNT);
        liquidAX.borrow(COLLATERAL_AMOUNT, BORROW_AMOUNT);
        vm.stopPrank();

        assertEq(
            collateralToken.balanceOf(address(liquidAX)),
            COLLATERAL_AMOUNT
        );
        assertEq(laxdToken.balanceOf(address(liquidAX)), BORROW_AMOUNT);

        (uint256 collateral, uint256 borrowed, , , ) = liquidAX.borrowings(
            user
        );
        assertEq(collateral, COLLATERAL_AMOUNT);
        assertEq(borrowed, BORROW_AMOUNT);
    }

    function testWithdraw() public {
        // First borrow
        vm.startPrank(user);
        collateralToken.approve(address(liquidAX), COLLATERAL_AMOUNT);
        liquidAX.borrow(COLLATERAL_AMOUNT, BORROW_AMOUNT);

        // Advance time to meet withdrawal delay
        vm.warp(block.timestamp + liquidAX.WITHDRAWAL_DELAY() + 1);

        // Withdraw
        liquidAX.withdraw();
        vm.stopPrank();

        assertEq(laxdToken.balanceOf(user), BORROW_AMOUNT);

        (, , uint256 isWithdrawn, , ) = liquidAX.borrowings(user);
        assertTrue(isWithdrawn == 1);
    }
}
