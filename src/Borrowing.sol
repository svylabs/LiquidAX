// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Borrowing {
    struct BorrowingData {
        uint256 collateralAmount;
        uint256 borrowAmount;
        uint256 borrowTime;
        bool isLiquidated;
        bool isWithdrawn;
        uint256 feePercentage;
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
        self.feePercentage = 0;
    }

    function calculateRatio(
        BorrowingData storage self
    ) internal view returns (uint256) {
        return (self.borrowAmount * 1e18) / self.collateralAmount;
    }

    // Additional functions can be added here to manage borrowing operations
}
