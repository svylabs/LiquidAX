// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Borrowing {
    struct BorrowingData {
        uint256 collateralAmount;
        uint256 borrowAmount;
        uint256 borrowTime;
        bool isLiquidated;
        bool isWithdrawn;
        uint256 feePercentage; // Fee percentage paid by the user
        uint256 totalFeePaid; // Total fee paid by the user
        // Discount for new users. They do not start from 0 fee, instead they start from the lowest fee % paid at that time they
        // begin borrowing. Only changes how the accounting is done, not the actual fee paid.
        uint256 discountFee;
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
        self.totalFeePaid = 0;
        self.discountFee = 0;
    }

    function calculateRatio(
        BorrowingData storage self
    ) internal view returns (uint256) {
        return (self.borrowAmount * 1e18) / self.collateralAmount;
    }

    // Additional functions can be added here to manage borrowing operations
}
