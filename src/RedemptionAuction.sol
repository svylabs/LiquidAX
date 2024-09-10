pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LiquidAX.sol";
import "./OrderedDoublyLinkedList.sol";

contract RedemptionAuction is ReentrancyGuard {
    using OrderedDoublyLinkedList for OrderedDoublyLinkedList.List;

    IERC20 public laxdToken;

    uint256 public constant AUCTION_DURATION = 20 minutes;
    uint256 public constant EXTENSION_DURATION = 20 minutes;
    uint256 public constant OPT_OUT_DURATION = 5 minutes;
    uint256 public constant REDEMPTION_THRESHOLD = 67;

    uint256 public endTime;
    uint256 public totalRedeemBets;
    uint256 public totalAntiRedeemBets;
    uint256 public winningRedeemPrice;
    bool public isRedeemWinning;
    bool public finalized;
    uint256 public totalStablecoinForRedemption;
    uint256 public optOutEndTime;

    OrderedDoublyLinkedList.List public redeemPrices;
    mapping(address => Bid) public bids;
    mapping(address => bool) public hasOptedOut;

    struct Bid {
        bool shouldRedeem;
        uint256 redeemPrice;
        uint256 bet;
        bool finalized;
    }

    event BidPlaced(
        address bidder,
        bool shouldRedeem,
        uint256 redeemPrice,
        uint256 bet
    );
    event BidIncreased(address bidder, uint256 additionalBet);
    event AuctionExtended(uint256 newEndTime);
    event AuctionFinalized(bool redemptionOccurred, uint256 redeemPrice);
    event OptedOut(address user);
    event OptedIn(address user);

    constructor(address _laxdToken) {
        laxdToken = IERC20(_laxdToken);
        endTime = block.timestamp + AUCTION_DURATION;
    }

    function placeBid(
        bool shouldRedeem,
        uint256 redeemPrice,
        uint256 bet,
        uint256 nearestSpot
    ) external nonReentrant {
        require(block.timestamp < endTime, "Auction ended");
        require(bet > 0, "Bet must be greater than 0");
        require(
            laxdToken.transferFrom(msg.sender, address(this), bet),
            "Transfer failed"
        );

        Bid storage userBid = bids[msg.sender];
        require(
            userBid.bet == 0,
            "Bid already placed. Use increaseBet() to add more."
        );

        userBid.shouldRedeem = shouldRedeem;
        userBid.redeemPrice = redeemPrice;
        userBid.bet = bet;

        if (shouldRedeem) {
            totalRedeemBets += bet;
            //if (!redeemPrices.contains(redeemPrice)) {
            redeemPrices.upsert(
                uint256(uint160(msg.sender)),
                redeemPrice,
                nearestSpot
            );
            //}
            if (totalRedeemBets > totalAntiRedeemBets && !isRedeemWinning) {
                extendAuction();
            }
            isRedeemWinning = true;
            updateWinningRedeemPrice();
        } else {
            totalAntiRedeemBets += bet;
            if (totalAntiRedeemBets > totalRedeemBets && isRedeemWinning) {
                extendAuction();
            }
            isRedeemWinning = false;
        }

        emit BidPlaced(msg.sender, shouldRedeem, redeemPrice, bet);
    }

    function increaseBet(uint256 additionalBet) external nonReentrant {
        require(block.timestamp < endTime, "Auction ended");
        require(additionalBet > 0, "Additional bet must be greater than 0");
        require(
            laxdToken.transferFrom(msg.sender, address(this), additionalBet),
            "Transfer failed"
        );

        Bid storage userBid = bids[msg.sender];
        require(userBid.bet > 0, "No existing bid found");

        userBid.bet += additionalBet;

        if (userBid.shouldRedeem) {
            totalRedeemBets += additionalBet;
            if (totalRedeemBets > totalAntiRedeemBets && !isRedeemWinning) {
                extendAuction();
            }
            isRedeemWinning = true;
        } else {
            totalAntiRedeemBets += additionalBet;
            if (totalAntiRedeemBets > totalRedeemBets && isRedeemWinning) {
                extendAuction();
            }
            isRedeemWinning = false;
        }

        emit BidIncreased(msg.sender, additionalBet);
    }

    function updateWinningRedeemPrice() private {
        //if (!redeemPrices.isEmpty()) {
        uint256 tail = redeemPrices.getTail();
        winningRedeemPrice = redeemPrices.getNode(tail).value;
        //}
    }

    function extendAuction() private {
        endTime = block.timestamp + EXTENSION_DURATION;
        emit AuctionExtended(endTime);
    }

    function finalizeAuction() external nonReentrant {
        require(block.timestamp >= endTime, "Auction not ended");
        require(!finalized, "Auction already finalized");

        finalized = true;
        optOutEndTime = block.timestamp + OPT_OUT_DURATION;

        if (isRedeemWinning) {
            totalStablecoinForRedemption = totalRedeemBets;
        }

        emit AuctionFinalized(isRedeemWinning, winningRedeemPrice);
    }

    function optOut() external nonReentrant {
        require(finalized, "Auction not finalized");
        require(block.timestamp < optOutEndTime, "Opt-out period ended");
        require(isRedeemWinning, "Redemption did not win");
        require(!hasOptedOut[msg.sender], "Already opted out");

        Bid storage userBid = bids[msg.sender];
        require(userBid.shouldRedeem, "Only redeem side can opt out");

        hasOptedOut[msg.sender] = true;
        totalStablecoinForRedemption -= userBid.bet;

        emit OptedOut(msg.sender);
    }

    function optIn() external nonReentrant {
        require(finalized, "Auction not finalized");
        require(block.timestamp < optOutEndTime, "Opt-out period ended");
        require(isRedeemWinning, "Redemption did not win");
        require(hasOptedOut[msg.sender], "Not opted out");

        Bid storage userBid = bids[msg.sender];
        require(userBid.shouldRedeem, "Only redeem side can opt in");

        hasOptedOut[msg.sender] = false;
        totalStablecoinForRedemption += userBid.bet;

        emit OptedIn(msg.sender);
    }

    function canExecuteRedemption() public view returns (bool) {
        if (!isRedeemWinning || block.timestamp < optOutEndTime) {
            return false;
        }
        uint256 redemptionThreshold = (totalRedeemBets * REDEMPTION_THRESHOLD) /
            100;
        return totalStablecoinForRedemption >= redemptionThreshold;
    }

    function getTail() public view returns (uint256) {
        return redeemPrices.getTail();
    }

    function getNode(
        uint256 index
    ) public view returns (OrderedDoublyLinkedList.Node memory) {
        return redeemPrices.getNode(index);
    }

    function getBid(address bidder) public returns (Bid memory) {
        return bids[bidder];
    }

    function finalizeBid(address bidder) public {
        bids[bidder].finalized = true;
    }
}

contract RedemptionAuctionManager is ReentrancyGuard {
    LiquidAX public liquidAX;
    IERC20 public laxdToken;
    IERC20 public collateralToken;

    RedemptionAuction public currentAuction;

    uint256 private constant MAX_FEE_PERCENTAGE = 5;
    uint256 public redeemPrice;
    uint256 public totalRedeemedCollateral;
    uint256 public totalAntiRedeemBets;
    address public highestBidder;
    uint256 public feePercentage;

    event AuctionStarted(address auctionAddress);
    event RedemptionExecuted(uint256 redeemPrice, uint256 totalRedeemed);

    constructor(
        address _liquidAX,
        address _laxdToken,
        address _collateralToken
    ) {
        liquidAX = LiquidAX(_liquidAX);
        laxdToken = IERC20(_laxdToken);
        collateralToken = IERC20(_collateralToken);
    }

    function startAuction() external nonReentrant {
        require(
            address(currentAuction) == address(0) || currentAuction.finalized(),
            "Auction in progress"
        );
        currentAuction = new RedemptionAuction(address(laxdToken));
        emit AuctionStarted(address(currentAuction));
    }

    function executeRedemption() external nonReentrant {
        require(address(currentAuction) != address(0), "No auction exists");
        require(
            currentAuction.canExecuteRedemption(),
            "Cannot execute redemption"
        );

        redeemPrice = currentAuction.winningRedeemPrice();
        uint256 totalToRedeem = currentAuction.totalStablecoinForRedemption();
        totalRedeemedCollateral = (totalToRedeem * 1e18) / redeemPrice;
        totalAntiRedeemBets = currentAuction.totalAntiRedeemBets();

        require(
            collateralToken.transferFrom(
                address(liquidAX),
                address(this),
                totalRedeemedCollateral
            ),
            "Collateral transfer failed"
        );

        uint256 tail = currentAuction.getTail();

        highestBidder = address(uint160(tail));
        RedemptionAuction.Bid memory bid = currentAuction.getBid(highestBidder);
        uint256 highestBidAmount = bid.bet;
        feePercentage = (highestBidAmount * MAX_FEE_PERCENTAGE) / totalToRedeem;

        emit RedemptionExecuted(redeemPrice, totalToRedeem);

        currentAuction = RedemptionAuction(address(0));
    }

    function withdraw() external nonReentrant {
        require(redeemPrice > 0, "Redemption not executed");
        RedemptionAuction.Bid memory bid = currentAuction.getBid(msg.sender);
        require(bid.bet > 0, "No bid found");
        require(bid.finalized == false, "Bidder is already finalized");
        require(
            bid.shouldRedeem && !currentAuction.hasOptedOut(msg.sender),
            "Not eligible for withdrawal"
        );

        uint256 collateralShare = (bid.bet * 1e18) / redeemPrice;
        uint256 feeShare = (bid.bet * totalAntiRedeemBets) /
            currentAuction.totalRedeemBets();
        uint256 totalWithdrawal = collateralShare + feeShare;

        if (msg.sender == highestBidder) {
            uint256 additionalFee = (totalWithdrawal * feePercentage) / 100;
            totalWithdrawal += additionalFee;
        }

        require(
            collateralToken.transfer(msg.sender, totalWithdrawal),
            "Transfer failed"
        );

        // Reset user's bid to prevent double withdrawal
        currentAuction.finalizeBid(msg.sender);
    }

    // Additional functions for interacting with the current auction can be added here
}
