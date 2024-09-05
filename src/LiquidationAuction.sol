// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./OrderedDoublyLinkedList.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IStabilityPool.sol";

interface IBurnableToken is IERC20 {
    function burn(address account, uint256 amount) external;
}

contract Auction is ReentrancyGuard {
    using OrderedDoublyLinkedList for OrderedDoublyLinkedList.List;
    uint256 public constant AUCTION_DURATION = 24 hours;
    uint256 public constant BID_EXTENSION_PERIOD = 1 hours;
    uint256 public auctionEndTime;
    bool public isLiquidationWinning;

    uint256 public tokenId;
    uint256 public startTime;
    uint256 public liquidationBetsSum;
    uint256 public nonLiquidationBetsSum;
    OrderedDoublyLinkedList.List public liquidationBids;
    OrderedDoublyLinkedList.List public nonLiquidationBids;
    uint256 public borrowAmount;
    uint256 public collateralAmount;
    bool public isFinalized;
    uint256 public constant MIN_LIQUIDATION_THRESHOLD = 110; // 110%
    uint256 public liquidationTargetThreshold;
    uint256 public targetRepayAmount;
    mapping(uint256 => address) public bidToAddress;

    IERC20 public collateralToken;
    IBurnableToken public laxdToken;
    address public owner;

    mapping(address => uint256) public liquidationStakes;
    mapping(address => uint256) public nonLiquidationStakes;

    mapping(address => bool) public userWantsToRepay;
    uint256 public usersWillingToRepay;

    LiquidationAuction public liquidationAuctionContract;

    IStabilityPool public stabilityPool;
    mapping(address => uint256) public stabilityPoolBorrows;
    uint256 public totalStabilityPoolBorrow;

    event BidPlaced(
        address bidder,
        uint256 amount,
        uint256 repayAmount,
        bool isLiquidation
    );
    event RewardWithdrawn(address bidder, uint256 amount);
    event AuctionFinalized(bool isLiquidated);
    event AuctionEndTimeUpdated(uint256 newEndTime);
    event BidIncreased(address bidder, uint256 additionalAmount);
    event RepaymentIntentionChanged(
        address bidder,
        bool wantsToRepay,
        uint256 newRepayAmount
    );
    event LiquidationThresholdUpdated(uint256 newThreshold);

    constructor(
        uint256 _tokenId,
        uint256 _borrowAmount,
        uint256 _collateralAmount,
        address _collateralToken,
        address _laxdToken,
        address _owner,
        address _liquidationAuctionContract,
        address _stabilityPool
    ) {
        tokenId = _tokenId;
        startTime = block.timestamp;
        borrowAmount = _borrowAmount;
        collateralAmount = _collateralAmount;
        collateralToken = IERC20(_collateralToken);
        laxdToken = IBurnableToken(_laxdToken);
        owner = _owner;
        auctionEndTime = block.timestamp + BID_EXTENSION_PERIOD;
        isLiquidationWinning = false; // Initially, non-liquidation side is winning
        liquidationAuctionContract = LiquidationAuction(
            _liquidationAuctionContract
        );
        liquidationTargetThreshold = liquidationAuctionContract
            .LIQUIDATION_TARGET_THRESHOLD();
        stabilityPool = IStabilityPool(_stabilityPool);
        updateTargetRepayAmount();
    }

    function getBidId() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(msg.sender, tokenId)));
    }

    // Implement placeBid, finalizeAuction, distributeLiquidationRewards,
    // distributeNonLiquidationRewards, and other necessary functions here
    // ...

    function placeBid(
        uint256 repayAmount,
        uint256 nearestSpot
    ) external payable nonReentrant {
        require(block.timestamp < auctionEndTime, "Auction ended");
        require(msg.value > 0, "Bid amount must be greater than 0");
        uint256 bidId = getBidId();

        bool isLiquidation = repayAmount < targetRepayAmount;

        if (isLiquidation) {
            uint256 userLaxdBalance = laxdToken.balanceOf(msg.sender);
            uint256 stabilityPoolBorrow = 0;

            if (userLaxdBalance < repayAmount) {
                stabilityPoolBorrow = repayAmount - userLaxdBalance;
                require(
                    stabilityPool.canBorrow(msg.sender, stabilityPoolBorrow),
                    "Insufficient funds in Stability Pool"
                );

                uint256 additionalBorrow = 0;
                if (stabilityPoolBorrow > totalStabilityPoolBorrow) {
                    additionalBorrow =
                        stabilityPoolBorrow -
                        totalStabilityPoolBorrow;
                    stabilityPool.borrow(address(this), additionalBorrow);
                    totalStabilityPoolBorrow += additionalBorrow;
                }

                stabilityPoolBorrows[msg.sender] += stabilityPoolBorrow;
            }

            // Transfer user's LAXD tokens
            if (userLaxdBalance > 0) {
                uint256 transferAmount = Math.min(userLaxdBalance, repayAmount);
                require(
                    laxdToken.transferFrom(
                        msg.sender,
                        address(this),
                        transferAmount
                    ),
                    "LAXD transfer failed"
                );
            }
        }

        bidToAddress[bidId] = msg.sender;

        bool leadChanged = false;

        if (isLiquidation) {
            liquidationBetsSum += msg.value;
            liquidationStakes[msg.sender] += msg.value;
            OrderedDoublyLinkedList.insert(
                liquidationBids,
                bidId,
                repayAmount,
                nearestSpot
            );
            if (repayAmount > 0) {
                userWantsToRepay[msg.sender] = true;
                usersWillingToRepay++;
            }
            if (
                liquidationBetsSum > nonLiquidationBetsSum &&
                !isLiquidationWinning
            ) {
                isLiquidationWinning = true;
                leadChanged = true;
            }
        } else {
            nonLiquidationBetsSum += msg.value;
            nonLiquidationStakes[msg.sender] += msg.value;
            OrderedDoublyLinkedList.insert(
                nonLiquidationBids,
                bidId,
                repayAmount,
                nearestSpot
            );
            if (
                nonLiquidationBetsSum > liquidationBetsSum &&
                isLiquidationWinning
            ) {
                isLiquidationWinning = false;
                leadChanged = true;
            }
        }

        if (leadChanged) {
            updateAuctionEndTime();
        }

        emit BidPlaced(msg.sender, msg.value, repayAmount, isLiquidation);
    }

    function increaseBid() external payable nonReentrant {
        require(block.timestamp < auctionEndTime, "Auction ended");
        require(msg.value > 0, "Increase amount must be greater than 0");

        bool isLiquidation = liquidationStakes[msg.sender] > 0;

        if (isLiquidation) {
            liquidationBetsSum += msg.value;
            liquidationStakes[msg.sender] += msg.value;
        } else {
            nonLiquidationBetsSum += msg.value;
            nonLiquidationStakes[msg.sender] += msg.value;
        }

        bool leadChanged = updateLeadingBidSide();
        if (leadChanged) {
            updateAuctionEndTime();
        }

        emit BidIncreased(msg.sender, msg.value);
    }

    function changeRepaymentIntention(
        bool wantsToRepay,
        uint256 newRepayAmount,
        uint256 nearestSpot
    ) external nonReentrant {
        require(block.timestamp < auctionEndTime, "Auction ended");
        require(
            liquidationStakes[msg.sender] > 0,
            "No liquidation stake found"
        );
        require(
            wantsToRepay || usersWillingToRepay > 1,
            "At least one user must be willing to repay"
        );

        uint256 bidId = getBidId();
        bool currentIntention = userWantsToRepay[msg.sender];

        if (currentIntention != wantsToRepay) {
            userWantsToRepay[msg.sender] = wantsToRepay;
            if (wantsToRepay) {
                usersWillingToRepay++;
            } else {
                usersWillingToRepay--;
            }
        }

        if (wantsToRepay) {
            require(newRepayAmount > 0, "Repay amount must be greater than 0");
            require(
                newRepayAmount >= borrowAmount,
                "Repay amount low for liquidation"
            );
            OrderedDoublyLinkedList.upsert(
                liquidationBids,
                bidId,
                newRepayAmount,
                nearestSpot
            );
        } else {
            require(
                OrderedDoublyLinkedList.getHead(liquidationBids) !=
                    OrderedDoublyLinkedList.getTail(liquidationBids),
                "Cannot remove the only repayment bid"
            );
            OrderedDoublyLinkedList.remove(liquidationBids, bidId);
        }

        emit RepaymentIntentionChanged(
            msg.sender,
            wantsToRepay,
            newRepayAmount
        );
    }

    function updateLeadingBidSide() private returns (bool) {
        bool previousLeader = isLiquidationWinning;
        isLiquidationWinning = liquidationBetsSum > nonLiquidationBetsSum;
        return previousLeader != isLiquidationWinning;
    }

    function updateAuctionEndTime() private {
        auctionEndTime = block.timestamp + BID_EXTENSION_PERIOD;
        emit AuctionEndTimeUpdated(auctionEndTime);
    }

    function withdrawRewards() external nonReentrant {
        require(isFinalized, "Auction not finalized");

        uint256 reward;
        if (liquidationBetsSum > nonLiquidationBetsSum) {
            uint256 stake = liquidationStakes[msg.sender];
            require(stake > 0, "No liquidation stake");
            reward = (stake * collateralAmount) / liquidationBetsSum;
            liquidationStakes[msg.sender] = 0;
        } else {
            uint256 stake = nonLiquidationStakes[msg.sender];
            require(stake > 0, "No non-liquidation stake");
            reward =
                (stake * (liquidationBetsSum + nonLiquidationBetsSum)) /
                nonLiquidationBetsSum;
            nonLiquidationStakes[msg.sender] = 0;
        }

        require(reward > 0, "No rewards to withdraw");
        collateralToken.transfer(msg.sender, reward);

        emit RewardWithdrawn(msg.sender, reward);
    }

    function finalizeAuction() external {
        require(msg.sender == owner, "Only owner can finalize");
        require(block.timestamp >= auctionEndTime, "Auction not ended");
        require(!isFinalized, "Already finalized");

        isFinalized = true;

        if (liquidationBetsSum > nonLiquidationBetsSum) {
            // Handle liquidation case
            uint256 highestBid = liquidationBids.getTail();
            address winner = bidToAddress[highestBid];
            uint256 repayAmount = liquidationBids.get(highestBid).value;

            handleRepayment(winner, repayAmount);
            laxdToken.burn(address(this), borrowAmount);

            // Update liquidation threshold after finalization
            updateLiquidationThreshold(repayAmount);
        } else {
            // Handle non-liquidation case
            collateralToken.transfer(owner, collateralAmount);
        }

        emit AuctionFinalized(liquidationBetsSum > nonLiquidationBetsSum);
    }

    function withdrawCollateral(address recipient) external {
        require(msg.sender == owner, "Only owner can withdraw collateral");
        require(isFinalized, "Auction not finalized");
        require(
            nonLiquidationBetsSum > liquidationBetsSum,
            "Liquidation occurred"
        );

        collateralToken.transfer(recipient, collateralAmount);
    }

    function burnLAXD() external {
        require(msg.sender == owner, "Only owner can burn LAXD");
        require(isFinalized, "Auction not finalized");
        require(
            liquidationBetsSum > nonLiquidationBetsSum,
            "No liquidation occurred"
        );

        uint256 highestBid = liquidationBids.getHead();
        uint256 repayAmount = liquidationBids.get(highestBid).value;
        //Bid memory bid = abi.decode(highestBid.data, (Bid));
        laxdToken.burn(address(this), repayAmount);
    }

    function updateTargetRepayAmount() private {
        targetRepayAmount = (borrowAmount * liquidationTargetThreshold) / 100;
    }

    function updateLiquidationThreshold(uint256 finalRepayValue) private {
        uint256 repayPercentage = (finalRepayValue * 100) / borrowAmount;
        uint256 oldThreshold = liquidationTargetThreshold;

        if (repayPercentage <= MIN_LIQUIDATION_THRESHOLD) {
            uint256 increase = MIN_LIQUIDATION_THRESHOLD - repayPercentage;
            liquidationTargetThreshold += increase;
        } else if (repayPercentage > MIN_LIQUIDATION_THRESHOLD) {
            uint256 decrease = repayPercentage - MIN_LIQUIDATION_THRESHOLD;
            liquidationTargetThreshold = Math.max(
                MIN_LIQUIDATION_THRESHOLD,
                liquidationTargetThreshold - decrease
            );
        }

        liquidationAuctionContract.updateLiquidationThreshold(
            tokenId,
            oldThreshold,
            liquidationTargetThreshold
        );
        emit LiquidationThresholdUpdated(liquidationTargetThreshold);
    }

    function handleRepayment(address winner, uint256 repayAmount) internal {
        uint256 stabilityPoolBorrow = stabilityPoolBorrows[winner];
        if (stabilityPoolBorrow > 0) {
            uint256 repayToStabilityPool = Math.min(
                stabilityPoolBorrow,
                repayAmount
            );
            laxdToken.transfer(address(stabilityPool), repayToStabilityPool);
            stabilityPool.repay(winner, repayToStabilityPool);
            stabilityPoolBorrows[winner] -= repayToStabilityPool;
            totalStabilityPoolBorrow -= repayToStabilityPool;
            repayAmount -= repayToStabilityPool;
        }

        if (repayAmount > 0) {
            laxdToken.burn(address(this), repayAmount);
        }
    }
}

contract LiquidationAuction is Ownable {
    uint256 public LIQUIDATION_TARGET_THRESHOLD = 110; // 110%

    IERC20 public collateralToken;
    IBurnableToken public laxdToken;
    IStabilityPool public stabilityPool;

    mapping(uint256 => address) public auctionToTokenId;

    event LiquidationThresholdUpdated(uint256 newThreshold);
    event AuctionStarted(
        uint256 indexed tokenId,
        address indexed auctionAddress,
        uint256 repayAmount,
        uint256 initialBet
    );

    constructor(
        address _collateralToken,
        address _laxdToken,
        address _stabilityPool
    ) Ownable(msg.sender) {
        collateralToken = IERC20(_collateralToken);
        laxdToken = IBurnableToken(_laxdToken);
        stabilityPool = IStabilityPool(_stabilityPool);
    }

    function initiateAuction(
        uint256 tokenId,
        uint256 repayAmount,
        uint256 borrowAmount,
        uint256 collateralAmount
    ) external payable onlyOwner {
        uint256 betAmount = msg.value;
        bool isLiquidation = isLiquidationAuction(borrowAmount, repayAmount);

        Auction newAuction = createAuction(
            tokenId,
            borrowAmount,
            collateralAmount
        );
        auctionToTokenId[tokenId] = address(newAuction);

        // Initialize the auction with the first bid
        // This part needs to be implemented in the Auction contract
        // newAuction.placeBid{value: betAmount}(repayAmount, isLiquidation);

        emit AuctionStarted(
            tokenId,
            address(newAuction),
            repayAmount,
            betAmount
        );
    }

    function createAuction(
        uint256 tokenId,
        uint256 borrowAmount,
        uint256 collateralAmount
    ) internal returns (Auction) {
        return
            new Auction(
                tokenId,
                borrowAmount,
                collateralAmount,
                address(collateralToken),
                address(laxdToken),
                msg.sender,
                address(this),
                address(stabilityPool)
            );
    }

    function isLiquidationAuction(
        uint256 borrowAmount,
        uint256 repayAmount
    ) internal view returns (bool) {
        uint256 targetRepayAmount = (borrowAmount *
            (100 + LIQUIDATION_TARGET_THRESHOLD)) / 100;
        return repayAmount < targetRepayAmount;
    }

    function updateLiquidationThreshold(
        uint256 tokenId,
        uint256 oldThreshold,
        uint256 newThreshold
    ) external {
        require(msg.sender == owner(), "Only owner can update threshold");
        require(newThreshold >= 110, "Threshold must be at least 110%");
        LIQUIDATION_TARGET_THRESHOLD = newThreshold;
        emit LiquidationThresholdUpdated(newThreshold);
    }

    function removeAuction(uint256 tokenId) external onlyOwner {
        delete auctionToTokenId[tokenId];
    }

    function isAuctionActive(uint256 tokenId) public view returns (bool) {
        return auctionToTokenId[tokenId] != address(0x0);
    }
    // Other functions like getAuctionDetails can be implemented here if needed
    // ...
}
