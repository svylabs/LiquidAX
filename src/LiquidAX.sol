// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./Borrowing.sol";
import "./LiquidationAuction.sol";
import "./LAXDToken.sol";
import "./OrderedDoublyLinkedList.sol";
import "./StabilityPool.sol";
import "./RedemptionAuction.sol";

contract LiquidAX is ERC721, ReentrancyGuard {
    using Borrowing for Borrowing.BorrowingData;
    using OrderedDoublyLinkedList for OrderedDoublyLinkedList.List;

    LAXDToken public laxdToken;
    IERC20 public collateralToken;
    LiquidationAuctionManager public liquidationAuction;
    StabilityPool public stabilityPool;
    RedemptionAuctionManager public redemptionAuction;

    mapping(uint256 => Borrowing.BorrowingData) public borrowings;
    OrderedDoublyLinkedList.List private borrowingsList;
    OrderedDoublyLinkedList.List private feePercentageList;

    uint256 public constant WITHDRAWAL_DELAY = 1 hours;
    uint256 public constant MAX_FEE_PERCENTAGE = 10000; // 100% in basis points

    constructor(address _collateralToken) ERC721("LiquidAX Borrowing", "LAXB") {
        collateralToken = IERC20(_collateralToken);
        laxdToken = new LAXDToken();
        stabilityPool = new StabilityPool(
            address(laxdToken),
            address(collateralToken)
        );
        liquidationAuction = new LiquidationAuctionManager(
            _collateralToken,
            address(laxdToken),
            address(stabilityPool)
        );
        redemptionAuction = new RedemptionAuctionManager(
            address(this),
            address(laxdToken),
            _collateralToken
        );
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
        uint256 externalId,
        uint256 feePercentage
    ) external nonReentrant returns (uint256) {
        require(canBorrow(externalId), "Borrowing already exists");
        require(
            collateralAmount > 0,
            "Collateral amount must be greater than 0"
        );
        require(borrowAmount > 0, "Borrow amount must be greater than 0");
        require(feePercentage <= MAX_FEE_PERCENTAGE, "Fee percentage too high");

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
        borrowings[externalId].feePercentage = feePercentage;

        // Insert into feePercentageList

        emit Borrowed(
            msg.sender,
            externalId,
            collateralAmount,
            borrowAmount,
            feePercentage
        );
        return externalId;
    }

    function withdraw(
        uint256 tokenId,
        uint256 nearestSpotForRatio,
        uint256 nearestSpotForFee
    ) external nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        Borrowing.BorrowingData storage borrowing = borrowings[tokenId];
        require(borrowing.borrowAmount > 0, "No active borrowing");
        require(!borrowing.isLiquidated, "Borrowing has been liquidated");
        require(!borrowing.isWithdrawn, "LAXD already withdrawn");
        require(
            block.timestamp >= borrowing.borrowTime + WITHDRAWAL_DELAY,
            "Withdrawal delay not met"
        );

        // Add check for ongoing auction
        require(
            !liquidationAuction.isAuctionActive(tokenId),
            "Auction is active"
        );

        borrowing.isWithdrawn = true;

        // Calculate fee
        uint256 feeAmount = (borrowing.borrowAmount * borrowing.feePercentage) /
            MAX_FEE_PERCENTAGE;
        uint256 amountToTransfer = borrowing.borrowAmount - feeAmount;

        // Transfer LAXD to borrower
        laxdToken.transfer(msg.sender, amountToTransfer);

        // Pay fee to stability pool
        laxdToken.approve(address(stabilityPool), feeAmount);
        stabilityPool.addLaxdReward(feeAmount);

        // Calculate the ratio (borrowAmount per collateral)
        uint256 ratio = (borrowing.borrowAmount * 1e18) /
            borrowing.collateralAmount;

        // Insert the borrowing into the ordered list
        borrowingsList.upsert(tokenId, ratio, nearestSpotForRatio);
        feePercentageList.upsert(
            tokenId,
            borrowing.feePercentage,
            nearestSpotForFee
        );

        emit Withdrawn(msg.sender, amountToTransfer, feeAmount);
    }

    function getLowestRiskBorrowing() public view returns (uint256) {
        return borrowingsList.getHead();
    }

    function getHighestRiskBorrowing() public view returns (uint256) {
        return borrowingsList.getTail();
    }

    function getBorrowingsListNode(
        uint256 id
    ) public view returns (OrderedDoublyLinkedList.Node memory) {
        return borrowingsList.getNode(id);
    }

    function getLowestFeePercentageBorrowing() public view returns (uint256) {
        return feePercentageList.getHead();
    }

    function redeem(
        address auctionAddress,
        uint256 amount,
        uint256 price
    ) public returns (address borrower, uint256 redeemedAmount) {
        require(amount > 0, "Amount must be greater than 0");

        uint256 tokenId = feePercentageList.getHead();
        //borrower = address(uint160(head));
        uint256 borrowAmount = borrowings[tokenId].borrowAmount;

        redeemedAmount = amount < borrowAmount ? amount : borrowAmount;

        // Transfer collateral to the borrower
        uint256 collateralAmount = calculateCollateralAmount(
            redeemedAmount,
            price
        );
        require(
            collateralToken.transfer(borrower, collateralAmount),
            "Collateral transfer failed"
        );

        // Assuming there's a burn function in the stablecoin contract
        laxdToken.burn(auctionAddress, redeemedAmount);

        // Update borrowing state
        borrowings[tokenId].borrowAmount -= redeemedAmount;
        if (borrowings[tokenId].borrowAmount == 0) {
            //borrowings.remove(tokenId);
            feePercentageList.remove(tokenId);
        }

        return (borrower, redeemedAmount);
    }

    function calculateCollateralAmount(
        uint256 amount,
        uint256 price
    ) internal pure returns (uint256) {
        return amount / price;
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
        uint256 borrowAmount,
        uint256 feePercentage
    );
    event Withdrawn(
        address indexed borrower,
        uint256 amount,
        uint256 feeAmount
    );
}
