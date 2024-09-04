// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./Borrowing.sol";
import "./LiquidationAuction.sol";
import "./LAXDTOken.sol";

contract LiquidAX is ERC721, ReentrancyGuard {
    using Borrowing for Borrowing.BorrowingData;

    LAXDToken public laxdToken;
    IERC20 public collateralToken;
    LiquidationAuction public liquidationAuction;

    mapping(uint256 => Borrowing.BorrowingData) public borrowings;

    uint256 public constant WITHDRAWAL_DELAY = 1 hours;

    constructor(address _collateralToken) ERC721("LiquidAX Borrowing", "LAXB") {
        collateralToken = IERC20(_collateralToken);
        laxdToken = new LAXDToken();
        liquidationAuction = new LiquidationAuction();
    }

    function canBorrow(uint256 externalId) public view returns (bool) {
        if (
            borrowings[externalId].borrowAmount == 0 &&
            !borrowings[externalId].isLiquidated &&
            !borrowings[externalId].isWithdrawn
        ) {
            return true;
        }
        if (ownerOf(externalId) == address(0)) {
            return true;
        }
        return false;
    }

    function borrow(
        uint256 collateralAmount,
        uint256 borrowAmount,
        uint256 externalId
    ) external nonReentrant returns (uint256) {
        require(canBorrow(externalId), "Borrowing already exists");
        require(
            collateralAmount > 0,
            "Collateral amount must be greater than 0"
        );
        require(borrowAmount > 0, "Borrow amount must be greater than 0");

        require(
            collateralToken.transferFrom(
                msg.sender,
                address(this),
                collateralAmount
            ),
            "Collateral transfer failed"
        );

        laxdToken.mint(address(this), borrowAmount);

        _safeMint(msg.sender, externalId);

        borrowings[externalId].initiateBorrowing(
            collateralAmount,
            borrowAmount
        );

        emit Borrowed(msg.sender, externalId, collateralAmount, borrowAmount);
        return externalId;
    }

    function withdraw(uint256 tokenId) external nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        Borrowing.BorrowingData storage borrowing = borrowings[tokenId];
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
        uint256 indexed externalId,
        uint256 collateralAmount,
        uint256 borrowAmount
    );
    event Withdrawn(address indexed borrower, uint256 amount);
}
