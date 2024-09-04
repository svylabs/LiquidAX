// SPDX-License-Identifier: MIT
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

    address user1 = address(1);
    address user2 = address(2);
    address user3 = address(3);

    function setUp() public {
        collateralToken = new MockERC20();
        liquidAX = new LiquidAX(address(collateralToken));
        laxdToken = liquidAX.laxdToken();

        collateralToken.mint(user, COLLATERAL_AMOUNT);
        collateralToken.mint(user1, 1000e18);
        collateralToken.mint(user2, 1000e18);
        collateralToken.mint(user3, 1000e18);
    }

    function testBorrow() public {
        uint256 externalId = 1;
        vm.startPrank(user);
        collateralToken.approve(address(liquidAX), COLLATERAL_AMOUNT);
        liquidAX.borrow(COLLATERAL_AMOUNT, BORROW_AMOUNT, externalId);
        vm.stopPrank();

        assertEq(
            collateralToken.balanceOf(address(liquidAX)),
            COLLATERAL_AMOUNT
        );
        assertEq(laxdToken.balanceOf(address(liquidAX)), BORROW_AMOUNT);

        (uint256 collateral, uint256 borrowed, , , ) = liquidAX.borrowings(
            externalId
        );
        assertEq(collateral, COLLATERAL_AMOUNT);
        assertEq(borrowed, BORROW_AMOUNT);
        assertEq(liquidAX.ownerOf(externalId), user);
    }

    function testWithdraw() public {
        // Create three borrowings with different ratios
        uint256 externalId1 = 1;
        uint256 externalId2 = 2;
        uint256 externalId3 = 3;

        vm.startPrank(user1);
        collateralToken.approve(address(liquidAX), 100e18);
        liquidAX.borrow(100e18, 50e18, externalId1);
        vm.stopPrank();

        vm.startPrank(user2);
        collateralToken.approve(address(liquidAX), 100e18);
        liquidAX.borrow(100e18, 75e18, externalId2);
        vm.stopPrank();

        vm.startPrank(user3);
        collateralToken.approve(address(liquidAX), 100e18);
        liquidAX.borrow(100e18, 25e18, externalId3);
        vm.stopPrank();

        // Advance time to meet withdrawal delay
        vm.warp(block.timestamp + liquidAX.WITHDRAWAL_DELAY() + 1);

        // Withdraw in reverse order to test insertion
        vm.prank(user3);
        liquidAX.withdraw(externalId3, 0);

        vm.prank(user2);
        liquidAX.withdraw(externalId2, 0);

        vm.prank(user1);
        liquidAX.withdraw(externalId1, 0);

        // Check if the borrowings are in the correct order
        assertEq(
            liquidAX.getLowestRiskBorrowing(),
            externalId3,
            "Lowest risk borrowing should be externalId3"
        );
        assertEq(
            liquidAX.getHighestRiskBorrowing(),
            externalId2,
            "Highest risk borrowing should be externalId2"
        );

        // Check the order of the list
        uint256 current = liquidAX.getLowestRiskBorrowing();
        assertEq(current, externalId3, "First in list should be externalId3");

        current = liquidAX.getBorrowingsListNode(current).next;
        assertEq(current, externalId1, "Second in list should be externalId1");

        current = liquidAX.getBorrowingsListNode(current).next;
        assertEq(current, externalId2, "Third in list should be externalId2");

        assertEq(
            liquidAX.getBorrowingsListNode(current).next,
            0,
            "Last node's next should be 0"
        );

        // Verify the ratios
        uint256 ratio1 = liquidAX.getBorrowingsListNode(externalId1).value;
        uint256 ratio2 = liquidAX.getBorrowingsListNode(externalId2).value;
        uint256 ratio3 = liquidAX.getBorrowingsListNode(externalId3).value;

        assertEq(
            ratio1,
            (50e18 * 1e18) / 100e18,
            "Ratio for externalId1 should be 0.5e18"
        );
        assertEq(
            ratio2,
            (75e18 * 1e18) / 100e18,
            "Ratio for externalId2 should be 0.75e18"
        );
        assertEq(
            ratio3,
            (25e18 * 1e18) / 100e18,
            "Ratio for externalId3 should be 0.25e18"
        );

        // Verify that the ratios are in ascending order
        assertTrue(
            ratio3 < ratio1 && ratio1 < ratio2,
            "Ratios should be in ascending order"
        );
    }

    function testNFTTransferSuccess() public {
        uint256 externalId = 1;
        address newOwner = address(2);

        // Setup: Borrow to mint NFT
        vm.startPrank(user);
        collateralToken.approve(address(liquidAX), COLLATERAL_AMOUNT);
        liquidAX.borrow(COLLATERAL_AMOUNT, BORROW_AMOUNT, externalId);

        // Transfer NFT
        liquidAX.transferFrom(user, newOwner, externalId);
        vm.stopPrank();

        // Assert
        assertEq(liquidAX.ownerOf(externalId), newOwner);
    }

    function testNFTTransferFailure() public {
        uint256 externalId = 1;
        address newOwner = address(2);

        // Setup: Borrow to mint NFT
        vm.startPrank(user);
        collateralToken.approve(address(liquidAX), COLLATERAL_AMOUNT);
        liquidAX.borrow(COLLATERAL_AMOUNT, BORROW_AMOUNT, externalId);

        // Attempt to transfer NFT from non-owner
        vm.stopPrank();
        vm.startPrank(newOwner);

        vm.expectRevert(
            abi.encodeWithSignature(
                "ERC721InsufficientApproval(address,uint256)",
                newOwner,
                externalId
            )
        );
        liquidAX.transferFrom(user, newOwner, externalId);
        vm.stopPrank();

        // Assert
        assertEq(liquidAX.ownerOf(externalId), user);
    }
}
