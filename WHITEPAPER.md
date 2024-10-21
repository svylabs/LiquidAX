                                            LiquidAX - A Decentralized, Oracle-Free Stablecoin Protocol
                                        Sridhar<sg@svylabs.com>, Gopalakrishnan G<gopalakrishnan.g@gov.in>

# Abstract

LiquidAX is a decentralized, oracle-free stablecoin protocol that enables users to borrow stablecoins against collateral with user-defined conditions and no reliance on external price feeds. The protocol introduces a unique auction-driven model for liquidations and redemptions, empowering market participants to determine when liquidations or redemptions should occur, rather than relying external oracles. Borrowers set their own fees at the time of borrowing, with the protocol prioritizing borrowings with lower fees during the redemption process, encouraging competition and efficiency. LiquidAX eliminates ongoing interest charges, opting instead for a dynamically payable fee based on borrowings, while dynamically adjusting collateral requirements to adapt to changing market conditions. The Stability Pool allows users to earn rewards from origination fees and participate in liquidation auctions, ensuring system-wide stability. By leveraging a decentralized auction system for both liquidations and redemptions, LiquidAX creates a secure, efficient, and market-driven stablecoin ecosystem.

# Introduction

LiquidAX introduces an innovative, oracle-free, and decentralized stablecoin protocol designed for borrowing, and achieving stability through redemption and liquidation using the key feature of market-driven auctions. Unlike traditional stablecoin models that rely on price oracles, LiquidAX enables users to influence both liquidation and redemption processes via open auctions, enhancing decentralization and security.

A user-defined origination fee model further distinguishes LiquidAX from other stablecoin protocols. Users can define their origination fees, updatable later by paying additional fees, with redemptions prioritizing the lowest fee percentage paid, enabling fair market-driven redemption process.

# Oracle-Free Stability: A Key Feature

LiquidAX’s core strength lies in its fully decentralized and oracle-free architecture. Traditional stablecoin systems often depend on external price feeds, which introduce centralization risks. LiquidAX eliminates this vulnerability by relying on a decentralized auction system to determine when liquidations or redemptions should occur. By allowing the community to drive these decisions through open bids, the protocol fosters a more secure and resilient ecosystem.

# Overview of LiquidAX Protocol

LiquidAX provides users with a mechanism to borrow stablecoins against collateral without requiring price oracles or charging interest. The system features:

- Borrowing: Users lock collateral to borrow stablecoins with no interest, paying only an adjustable origination fee.
- Liquidation: If the collateral’s value falls close to a liquidation threshold, a user-driven auction decides whether liquidation should proceed.
- Redemption: Stablecoin holders can redeem their stablecoins for collateral through a market-driven auction, with the process favoring redemption of collateral from those who have paid the lowest fees in terms of percentage.

# Borrowing Mechanism

## Borrowing Conditions

Users initiate borrowing by locking collateral tokens into the LiquidAX smart contract, specifying:

- Collateral Amount: The amount of collateral token deposited.
- Borrow Amount: The amount of stablecoins the user wishes to borrow.
- Origination Fee: An upfront fee paid by users at the time of borrowing.

Borrow requests are organized in a list ordered based on the borrow-to-collateral ratio, prioritizing more collateralized positions for later liquidation. Another list orders borrowings by fee percentage paid.

## Borrowing Delay and Withdrawal

After submitting a borrow request, the user must wait to withdraw stablecoins. During this time, the borrowing is subject to a potential liquidation auction. If no auction is triggered, or if the auction does not result in liquidation, the user can withdraw their stablecoins after the waiting period, set to 1 hour.

# Stability Pool

The Stability Pool is a key component of LiquidAX, designed to enhance the protocol's stability and provide additional incentives for participants.

## Stability Pool Mechanics

Users can stake their stablecoins in the Stability Pool, earning rewards in the form of a portion of the fees collected by the protocol. These rewards are distributed proportionally to the amount staked by each participant.

## Participation in Liquidation Auctions

The Stability Pool also plays a crucial role in liquidation auctions by providing liquidity. During a liquidation auction, users can repay 100% of the borrowed amount of stablecoins from the Stability Pool to place their bids. Any amount of repay amount during liquidation above the borrowed amount, the user has to cover themselves. After liquidation, stability pool users receive all the collateral at a discounted price, and a part of the repay amount upto 5%, while the bidder receives the winning proceeds from the bet depending on their share.

## Strategic Importance

The Stability Pool not only provides liquidity for liquidation auctions but also creates a mechanism for stablecoin holders to earn passive income. By staking their stablecoins, users contribute to the overall stability of the protocol while benefiting from the system's fees and liquidation processes.

# Liquidation Auction Mechanism

## Role of the Dealer

To initiate a liquidation auction, LiquidAX introduces the "dealer" concept. The dealer is a user who triggers the auction during the one-hour delay before stablecoin withdrawal or when the collateralization ratio falls near or below the liquidation threshold.

## Triggering a Liquidation Auction

Any user can trigger a liquidation auction by placing an open bid with

- Repay Amount: Amount of stablecoins a user is willing to repay the protocol when a liquidation event happens.
- Bet: Amount of money a user is willing to risk during the auction process either in favor of liquidation or non-liquidation.

## Auction Bidding Process

Other users can join the auction by placing their own open bids, specifying a repay value and bet. The auction remains open as long as new bids are placed within 20 minutes from the moment a lead is established by either side.

- Auction Duration: The auction concludes if no new bets are placed within 20 minutes from the moment a lead is established on either side. If one side continues to receive new bets while the other side does not, the auction will conclude based on the time of the earliest remaining bid from the side with the lead. This ensures that the auction's duration is influenced by competitive activity on both sides, preventing indefinite extensions due to one-sided bidding.
- Bid Incrementation: Participants cannot revise their bets once submitted. However, they can increase their bets during the auction by placing additional bids on their chosen side, which can influence the outcome and strengthen their position.
- Real-Time Repayment Decisions: During the auction, participants on the leading side have the option to decide whether to repay the debt, depending on market conditions and their assessment of the collateral's value. The protocol ensures that at least one participant repays the specified amount, ensuring that the debt is covered if liquidation occurs.
- Bid: The amount of money the user is willing to risk during the auction process. This bet represents the commitment to either repay the debt (if the auction favors liquidation) or contribute to the pool opposing liquidation. The bets determine the participants' stakes in the outcome of the auction.

The auction’s conclusion is dynamic, allowing for a responsive and fair process that encourages active participation and market-driven outcomes.

## Liquidation Trigger Conditions

Liquidation is triggered if, by the end of the auction, the cumulative bids on the side favoring liquidation exceed those on the opposing side. If the auction concludes without favoring liquidation, no liquidation occurs, and the auction closes as follows:

- If Liquidation Bids Win: The collateral is liquidated, and the participant with the highest repay value receives the collateral, while the losing side’s bets are forfeited and distributed among the winning side proportionally to their bet contributions.
- If Anti-Liquidation Bids Win: No liquidation occurs. The winning side receives back their bets, while the losing side forfeits their bets, which are distributed to the winning participants based on the proportion of their contributions.

This mechanism ensures that liquidation only takes place when deemed necessary by market participants, with transparent and open bidding determining the outcome.

# Redemption

## Redemption Auction Process

LiquidAX introduces an oracle free redemption auction mechanism that allows stablecoin holders to redeem their stablecoins for collateral in a decentralized and market-driven manner.

### Auction Initiation

Any stablecoin holder can initiate a redemption auction by placing a bid with the following parameters:

- Should Redeem: A binary value (Yes/No) indicating whether the user believes redemption should occur.
- Redeem Price: The price in stablecoins per unit of collateral that the user is willing to accept.
- Bet: The amount of stablecoins the user is willing to wager in favor of their bid.

Once initiated, the auction starts with a default duration of 20 minutes.

### Dynamic Auction Prolongation

If the leading side (either in favor or against redemption) changes during the auction, the auction duration is extended by an additional 20 minutes. This ensures that the auction remains active as long as participants are placing competitive bids, allowing for market-driven price discovery.

### Winning and Losing Sides

Winning Side: The side (redeem or anti-redeem) with the highest aggregate bets when the auction closes.

- If the redemption side wins, the highest Redeem Price from the winning side is chosen as the final price for all participants. The aggregated bets by the losing side is distributed to the winning side proportionally to their own bets.
- If the anti-redemption side wins, the auction concludes without any redemptions.

### Optional Redemption Participation

After the conclusion of the auction, winning users have 5 minutes to change their mind about redemption at a particular price. Users who do not wish to redeem at the final chosen Redeem Price can opt out. Redemptions will be processed only for the stablecoins of users who agree to the selected price. If more than 67% of the stablecoins initially set for redemption are withdrawn, the redemption is aborted, and no redemptions occur and the bets are also not redistributed to the winners.

### Auction Closure and Execution

Once the auction concludes:

- If Redemption Side Wins: Protocol redeems all participating stablecoin holders at the winning Redeem Price, provided they choose to redeem.
- If Anti-Redemption Side Wins: No redemption occurs.

The auction’s dynamic structure ensures that only when a significant portion of the community supports redemption, the process will proceed. The extension of auction time with leading-side changes allows for sufficient market participation, encouraging a fair and transparent price discovery mechanism.

# Economic Incentives

## Borrowers

- Borrowers are incentivized to maintain an appropriate collateralization ratio, as liquidations are only triggered when there is significant market consensus. The one-hour delay allows borrowers to reassess their positions before potential liquidation.
- Borrowers are incentivized to set competitive origination fees, as collateral with the lowest fees will be prioritized in redemption events.
- Borrowers benefit from a no-interest model, with only dynamically payable fee based on borrowing, updatable based on market conditions, making this a cost effective alternative for borrowers.

## Stability Pool Participants

Participants in the Stability Pool are encouraged to stake their stablecoins to earn a share of the origination fees, liquidation and redemption proceeds. This incentive structure makes staking in the Stability Pool an attractive option for users looking to passively earn rewards while contributing to the protocol’s overall stability.

## Auction Participants

- Participants are encouraged to place strategic bids, as they can profit from successful liquidation by being on the winning side. The protocol’s design ensures that liquidations are aligned with real market conditions, rewarding participants who contribute to accurate price discovery.
- Participants in redemption auctions benefit from purchasing collateral at market-determined prices, while those bidding closer to the final price incur lower fees. The auction process ensures market-driven price discovery.

# Risk Management

LiquidAX integrates several risk mitigation mechanisms:

- Overcollateralization: Borrow requests are ranked by collateralization ratios, ensuring that highly collateralized positions are less vulnerable to liquidation.
- Dynamic Auction Threshold: The protocol can adjust the liquidation threshold based on market conditions, maintaining stability.
- Delayed Withdrawals: The one-hour delay between borrowing and withdrawal provides a buffer period for market participants to evaluate and act on potential liquidation risks.
- Stability Pool: The Stability Pool acts as a buffer during liquidation and redemption events, providing liquidity and absorbing potential shocks to the system.

# Oracle-Free Architecture

LiquidAX’s reliance on on-chain auctions removes the need for price oracles, which are common points of vulnerability in other DeFi protocols. By allowing users to determine the value of collateral through open bids, LiquidAX avoids the risks associated with external data sources, such as manipulation or failure.

## On-Chain Market Forces

The protocol is driven by market participants who determine the value of collateral and debt through competitive bidding. This on-chain mechanism ensures that all decisions are decentralized and reflect the collective judgment of the network’s users.

## Decentralized Auction Mechanism

The decentralized auction process ensures that liquidation decisions are made transparently and fairly, without relying on external inputs. This not only enhances security but also increases trust in the protocol’s ability to manage collateral effectively.

# Governance and Future Development

LiquidAX is a decentralized protocol, with no central governance or governance token.

# Conclusion

LiquidAX introduces a new paradigm in decentralized finance by eliminating reliance on oracles and central governance. Through market-driven auction mechanisms, it allows users to dictate both liquidation and redemption outcomes, ensuring a system that adapts dynamically to real-world conditions. The protocol's user-defined origination fees, no-interest borrowing model, and Stability Pool create a flexible, efficient, and resilient stablecoin ecosystem.

By aligning incentives across borrowers, redeemers, and stakers, LiquidAX delivers a secure, decentralized, and transparent financial system that thrives in any market environment, offering a future-proof alternative to traditional stablecoin models.
