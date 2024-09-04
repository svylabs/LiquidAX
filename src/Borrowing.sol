// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Borrowing {
    struct BorrowingData {
        uint256 collateralAmount;
        uint256 borrowAmount;
        uint256 borrowTime;
        bool isLiquidated;
        bool isWithdrawn;
    }

    function initiateBorrowing(
        BorrowingData storage self,
        uint256 collateralAmount,
        uint256 borrowAmount
    ) internal {
        self.collateralAmount = collateralAmount;
        self.borrowAmount = borrowAmount;
        self.borrowTime = block.timestamp;
        self.isLiquidated = false;
        self.isWithdrawn = false;
    }

    // Additional functions can be added here to manage borrowing operations
}
