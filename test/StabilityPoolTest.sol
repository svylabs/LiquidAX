// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/StabilityPool.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockLAXD is ERC20 {
    constructor() ERC20("Mock LAXD", "LAXD") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}

contract StabilityPoolTest is Test {
    StabilityPool pool;
    MockLAXD laxd;
    address user1 = address(1);
    address user2 = address(2);
    address owner = address(3);

    function setUp() public {
        vm.startPrank(owner);
        laxd = new MockLAXD();
        pool = new StabilityPool(address(laxd));

        laxd.transfer(user1, 10000 * 10 ** 18);
        laxd.transfer(user2, 10000 * 10 ** 18);
    }

    function testDeposit() public {
        vm.startPrank(user1);
        laxd.approve(address(pool), 1000 * 10 ** 18);
        pool.deposit(1000 * 10 ** 18);
        vm.stopPrank();

        assertEq(pool.deposits(user1), 1000 * 10 ** 18);
        assertEq(pool.totalDeposits(), 1000 * 10 ** 18);
    }

    function testWithdraw() public {
        vm.startPrank(user1);
        laxd.approve(address(pool), 1000 * 10 ** 18);
        pool.deposit(1000 * 10 ** 18);
        vm.stopPrank();

        vm.prank(user1);
        pool.withdraw(500 * 10 ** 18);

        assertEq(pool.deposits(user1), 500 * 10 ** 18);
        assertEq(pool.totalDeposits(), 500 * 10 ** 18);
    }

    function testBorrow() public {
        vm.startPrank(user1);
        console.log(laxd.balanceOf(user1));
        laxd.approve(address(pool), 1000 * 10 ** 18);
        pool.deposit(1000 * 10 ** 18);

        vm.startPrank(owner);
        pool.borrow(user2, 500 * 10 ** 18);

        assertEq(laxd.balanceOf(user2), 10500 * 10 ** 18);
        assertEq(pool.totalDeposits(), 1000 * 10 ** 18);
    }

    function testAddReward() public {
        vm.startPrank(user1);
        laxd.approve(address(pool), 2000 * 10 ** 18);
        pool.deposit(1000 * 10 ** 18);
        pool.addReward(100 * 10 ** 18);
        vm.stopPrank();

        assertEq(pool.totalRewards(), 100 * 10 ** 18);
    }

    function testClaimReward() public {
        vm.startPrank(user1);
        laxd.approve(address(pool), 2000 * 10 ** 18);
        pool.deposit(1000 * 10 ** 18);
        vm.startPrank(user2);
        laxd.approve(address(pool), 2000 * 10 ** 18);
        pool.addReward(100 * 10 ** 18);
        vm.startPrank(user1);
        pool.claimReward();

        assertEq(pool.totalRewards(), 0);
        assertEq(laxd.balanceOf(user1), 9100 * 10 ** 18);
    }

    function testGetUserShare() public {
        vm.startPrank(user1);
        laxd.approve(address(pool), 1000 * 10 ** 18);
        pool.deposit(1000 * 10 ** 18);

        vm.startPrank(user2);
        laxd.approve(address(pool), 3000 * 10 ** 18);
        pool.deposit(3000 * 10 ** 18);

        assertEq(pool.getUserShare(user1), 250 * 10 ** 15); // 25%
        assertEq(pool.getUserShare(user2), 750 * 10 ** 15); // 75%
    }

    function testFailWithdrawTooMuch() public {
        vm.startPrank(user1);
        console.log(laxd.balanceOf(user1));
        laxd.approve(address(pool), 1000 * 10 ** 18);
        pool.deposit(1000 * 10 ** 18);
        //vm.expectRevert("Insufficient balance");
        pool.withdraw(2000 * 10 ** 18);
        // assertEq(laxd.balanceOf(user1), 11000 * 10 ** 18);
        //vm.stopPrank();
    }

    function testFailBorrowTooMuch() public {
        vm.startPrank(user1);
        console.log(laxd.balanceOf(user1));
        laxd.approve(address(pool), 1000 * 10 ** 18);
        pool.deposit(1000 * 10 ** 18);

        vm.startPrank(owner);
        // vm.expectRevert("Insufficient funds in pool");
        pool.borrow(user2, 2000 * 10 ** 18);
        //assertEq(laxd.balanceOf(user1), 9000 * 10 ** 18);
        //assertEq(laxd.balanceOf(user2), 12000 * 10 ** 18);
    }

    function testFailNonOwnerBorrow() public {
        vm.startPrank(user1);
        laxd.approve(address(pool), 1000 * 10 ** 18);
        pool.deposit(1000 * 10 ** 18);

        vm.startPrank(user2);
        vm.expectRevert("Ownable: caller is not the owner");
        pool.borrow(user2, 500 * 10 ** 18);
    }
}
