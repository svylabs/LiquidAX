pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LAXDToken.sol";
import "./Borrowing.sol";
import "./LiquidationAuction.sol";

contract LiquidAX is ReentrancyGuard {
    using Borrowing for Borrowing.BorrowingData;

    LAXDToken public laxdToken;
    IERC20 public collateralToken;
    LiquidationAuction public liquidationAuction;

    mapping(address => Borrowing.BorrowingData) public borrowings;

    uint256 public constant WITHDRAWAL_DELAY = 1 hours;

    constructor(address _collateralToken) {
        collateralToken = IERC20(_collateralToken);
        laxdToken = new LAXDToken();
        liquidationAuction = new LiquidationAuction();
    }

    function borrow(
        uint256 collateralAmount,
        uint256 borrowAmount
    ) external nonReentrant {
        require(
            collateralAmount > 0,
            "Collateral amount must be greater than 0"
        );
        require(borrowAmount > 0, "Borrow amount must be greater than 0");
        require(
            borrowings[msg.sender].borrowAmount == 0,
            "Existing borrow must be repaid first"
        );

        require(
            collateralToken.transferFrom(
                msg.sender,
                address(this),
                collateralAmount
            ),
            "Collateral transfer failed"
        );

        laxdToken.mint(address(this), borrowAmount);

        borrowings[msg.sender].initiateBorrowing(
            collateralAmount,
            borrowAmount
        );

        emit Borrowed(msg.sender, collateralAmount, borrowAmount);
    }

    function withdraw() external nonReentrant {
        Borrowing.BorrowingData storage borrowing = borrowings[msg.sender];
        require(borrowing.borrowAmount > 0, "No active borrowing");
        require(!borrowing.isLiquidated, "Borrowing has been liquidated");
        require(!borrowing.isWithdrawn, "LAXD already withdrawn");
        require(
            block.timestamp >= borrowing.borrowTime + WITHDRAWAL_DELAY,
            "Withdrawal delay not met"
        );

        borrowing.isWithdrawn = true;
        laxdToken.transfer(msg.sender, borrowing.borrowAmount);

        emit Withdrawn(msg.sender, borrowing.borrowAmount);
    }

    // Additional functions to be implemented:
    // - repay()
    // - initiateLiquidationAuction()
    // - finalizeLiquidation()
    // - adjustCollateral()

    event Borrowed(
        address indexed borrower,
        uint256 collateralAmount,
        uint256 borrowAmount
    );
    event Withdrawn(address indexed borrower, uint256 amount);
}
