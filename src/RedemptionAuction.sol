pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./OrderedDoublyLinkedList.sol";
import "./LiquidAX.sol";

contract RedemptionAuction is ReentrancyGuard {
    using OrderedDoublyLinkedList for OrderedDoublyLinkedList.List;

    LiquidAX public liquidAX;
    IERC20 public laxdToken;
    IERC20 public collateralToken;

    uint256 public constant AUCTION_DURATION = 1 hours;
    uint256 public constant LIQUIDATION_RATIO = 110; // 110%

    struct Auction {
        uint256 stablecoinAmount;
        uint256 baselinePrice;
        uint256 endTime;
        address initiator;
        bool finalized;
    }

    Auction public currentAuction;
    OrderedDoublyLinkedList.List private bids;

    event AuctionStarted(
        uint256 stablecoinAmount,
        uint256 baselinePrice,
        uint256 endTime
    );
    event BidPlaced(address bidder, uint256 price);
    event AuctionFinalized(
        address winner,
        uint256 price,
        uint256 collateralAmount
    );

    constructor(
        address _liquidAX,
        address _laxdToken,
        address _collateralToken
    ) {
        liquidAX = LiquidAX(_liquidAX);
        laxdToken = IERC20(_laxdToken);
        collateralToken = IERC20(_collateralToken);
    }

    function initiateRedemptionAuction(
        uint256 stablecoinAmount
    ) external nonReentrant {
        require(
            currentAuction.endTime < block.timestamp,
            "Auction already in progress"
        );
        require(
            stablecoinAmount > 0,
            "Stablecoin amount must be greater than 0"
        );

        uint256 lowestRatioBorrowingId = liquidAX
            .getLowestFeePercentageBorrowing();
        (uint256 collateralAmount, uint256 borrowAmount, , , , ) = liquidAX
            .borrowings(lowestRatioBorrowingId);

        uint256 baselinePrice = (stablecoinAmount * 1e18) /
            ((((borrowAmount * LIQUIDATION_RATIO) / 100) * 1e18) /
                collateralAmount);

        currentAuction = Auction({
            stablecoinAmount: stablecoinAmount,
            baselinePrice: baselinePrice,
            endTime: block.timestamp + AUCTION_DURATION,
            initiator: msg.sender,
            finalized: false
        });

        emit AuctionStarted(
            stablecoinAmount,
            baselinePrice,
            currentAuction.endTime
        );
    }

    function placeBid(
        uint256 price,
        uint256 nearestSpot
    ) external nonReentrant {
        require(block.timestamp < currentAuction.endTime, "Auction ended");
        require(
            price < currentAuction.baselinePrice,
            "Bid must be lower than baseline price"
        );

        bids.upsert(uint256(uint160(msg.sender)), price, nearestSpot);

        emit BidPlaced(msg.sender, price);
    }

    function finalizeAuction() external nonReentrant {
        require(
            block.timestamp >= currentAuction.endTime,
            "Auction not ended yet"
        );
        require(!currentAuction.finalized, "Auction already finalized");

        uint256 winningBidId = bids.getHead();
        address winner = address(uint160(winningBidId));
        uint256 winningPrice = bids.get(winningBidId).value;

        uint256 collateralAmount = (currentAuction.stablecoinAmount * 1e18) /
            winningPrice;

        require(
            laxdToken.transferFrom(
                winner,
                address(this),
                currentAuction.stablecoinAmount
            ),
            "LAXD transfer failed"
        );
        require(
            collateralToken.transfer(winner, collateralAmount),
            "Collateral transfer failed"
        );

        currentAuction.finalized = true;

        emit AuctionFinalized(winner, winningPrice, collateralAmount);

        // Reset bids for the next auction
        //bids = OrderedDoublyLinkedList.List(0, 0);
    }
}
