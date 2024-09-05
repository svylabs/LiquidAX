                                            LiquidAX - A Decentralized, Oracle-Free Stablecoin Protocol
                                                      Gopalakrishnan G<gopalakrishnan.g@gov.in>

# Abstract

LiquidAX is a decentralized, oracle-free stablecoin protocol enabling users to borrow stablecoins against collateral under user-defined conditions. The protocol features a unique liquidation auction mechanism driven by market participants, ensuring that liquidations occur only when deemed necessary by the community, rather than by external oracles. LiquidAX also includes a redemption mechanism, allowing stablecoin holders to redeem their stablecoins for collateral via a market-driven auction process. Borrowers can define their own origination fees, and redemptions prioritize collateral with the lowest fees. LiquidAX charges no ongoing interest, opting for a user set origination fee. The protocol adapts to all market conditions by adjusting collateral requirements and stablecoin value, serving as a dynamic alternative to traditional interest rates. Additionally, the Stability Pool allows users to stake stablecoins, earn rewards from origination fees, and participate in liquidation auctions. By eliminating reliance on external oracles and utilizing a user-driven auction system, LiquidAX ensures a secure, decentralized, and efficient stablecoin ecosystem.

# Introduction

LiquidAX introduces an innovative, oracle-free, and decentralized stablecoin protocol designed for borrowing, redemption, and liquidation, with the key feature of market-driven auctions. Unlike traditional stablecoin models that rely on price oracles, LiquidAX enables users to influence both liquidation and redemption processes via open auctions, enhancing decentralization and security.

A user-defined origination fee model and a redemption mechanism further distinguish LiquidAX from other stablecoin protocols. Users can define their origination fees, with redemptions prioritizing the lowest fees, enabling fair market-driven redemption processes.

# Oracle-Free Stability: A Key Feature

LiquidAX’s core strength lies in its fully decentralized and oracle-free architecture. Traditional stablecoin systems often depend on external price feeds, which introduce centralization risks. LiquidAX eliminates this vulnerability by relying on a decentralized auction system to determine when liquidations or redemptions should occur. By allowing the community to drive these decisions through open bids, the protocol fosters a more secure and resilient ecosystem.

# Overview of LiquidAX Protocol

LiquidAX provides users with a mechanism to borrow stablecoins against collateral without requiring price oracles or charging interest. The system features:

- Borrowing: Users lock collateral to borrow stablecoins with no interest, paying only a one-time origination fee.
- Liquidation: If the collateral’s value falls close to a liquidation threshold, a user-driven auction decides whether liquidation should proceed.
- Redemption: Stablecoin holders can redeem their stablecoins for collateral through a market-driven auction, with the process favoring borrowers who have set the lowest origination fees.

# Borrowing Mechanism

## Borrowing Conditions

Users initiate borrowing by locking collateral tokens into the LiquidAX smart contract, specifying:

- Collateral Amount: The amount of collateral token deposited.
- Borrow Amount: The amount of stablecoins the user wishes to borrow.
- Origination Fee: A one-time fee of 0.5% of the borrowed amount, paid upfront.

Borrow requests are organized in a list ordered based on the borrow-to-collateral ratio, prioritizing more collateralized positions for later liquidation.

Another list maintains borrowings that need clearance through the Liquidation Auction mechanism.

## Borrowing Delay and Withdrawal

After submitting a borrow request, the user must wait to withdraw stablecoins. During this time, the borrowing is subject to a potential liquidation auction. If no auction is triggered, or if the auction does not result in liquidation, the user can withdraw their stablecoins after the waiting period. Importantly, users incur no interest charges during this waiting period or at any time during the life of the loan.

## Market Condition Adaptation

LiquidAX is designed to operate effectively in all market conditions. The protocol adapts by varying the collateral requirements and the price of the stablecoin, which serves as a proxy for traditional interest rates:

- High Interest Rate Environments: As interest rates in the broader market rise, LiquidAX increases the collateral requirements for borrowing. This higher collateral ratio compensates for the increased cost of capital, maintaining the stability of the system.
- Low or Negative Interest Rate Environments: Conversely, in scenarios where interest rates are low or negative, LiquidAX decreases the collateral requirements. This is achieved by adjusting the price of the stablecoin relative to fiat, making it more favorable for borrowers while still ensuring the protocol’s security.

LiquidAX does not target a specific value for the stablecoin; instead, the stablecoin’s value is determined by market conditions and is dynamically adjusted through the collateral ratio and liquidation threshold. This approach ensures that the protocol remains resilient and responsive to varying economic conditions.

# Stability Pool

The Stability Pool is a key component of LiquidAX, designed to enhance the protocol's stability and provide additional incentives for participants.

## Stability Pool Mechanics

Users can stake their stablecoins in the Stability Pool, earning rewards in the form of a portion of the origination fees collected by the protocol. These rewards are distributed proportionally to the amount staked by each participant.

## Participation in Liquidation Auctions

The Stability Pool also plays a crucial role in liquidation auctions by providing liquidity. During a liquidation auction, users can repay 100% of the borrowed amount of stablecoins from the Stability Pool to place their bids. Any amount of repay amount during liquidation above the borrowed amount, the user has to cover themselves. After liquidation, stability pool users receive all the collateral at a discounted price, and a part of the repay amount upto 5%, while the bidder receives the winning proceeds from the bet depending on their share.

- Borrowing from the Stability Pool: Users borrowing stablecoins from the Stability Pool during a liquidation auction pay a fee equal to 10% of the winning bet proceeds. This fee is directed back to the Stability Pool, benefiting all stakers.
- Collateral Distribution: After a successful liquidation, 90% of the discounted collateral is distributed among the Stability Pool participants based on their stakes, while the remaining 10% is given to the user who placed the winning bid.

## Strategic Importance

The Stability Pool not only provides liquidity for liquidation auctions but also creates a mechanism for stablecoin holders to earn passive income. By staking their stablecoins, users contribute to the overall stability of the protocol while benefiting from the system's fees and liquidation processes.

# Liquidation Auction Mechanism

## Role of the Dealer

To initiate a liquidation auction, LiquidAX introduces the "dealer" concept. The dealer is a user who triggers the auction during the one-hour delay before stablecoin withdrawal or when the collateralization ratio falls near or below the liquidation threshold.

## Triggering a Liquidation Auction

During the one-hour delay, any user can trigger a liquidation auction by placing an open bid.

## Auction Bidding Process

Other users can join the auction by placing their own open bids, specifying a repay value and bet. The auction remains open as long as new bids are placed within one hour from the moment a lead is established by either side.

- Auction Duration: The auction concludes if no new bets are placed within one hour from the moment a lead is established on either side. If one side continues to receive new bets while the other side does not, the auction will conclude based on the time of the earliest remaining bid from the side with the lead. This ensures that the auction's duration is influenced by competitive activity on both sides, preventing indefinite extensions due to one-sided bidding.
- Bid Incrementation: Participants cannot revise their bets once submitted. However, they can increase their bets during the auction by placing additional bids on their chosen side, which can influence the outcome and strengthen their position.
- Real-Time Repayment Decisions: During the auction, participants on the leading side have the option to decide whether to repay the debt, depending on market conditions and their assessment of the collateral's value. The protocol ensures that at least one participant repays the specified amount, ensuring that the debt is covered if liquidation occurs.
  -Bid: The amount of money the user is willing to risk during the auction process. This bet represents the commitment to either repay the debt (if the auction favors liquidation) or contribute to the pool opposing liquidation. The bets determine the participants' stakes in the outcome of the auction.

The auction’s conclusion is dynamic, allowing for a responsive and fair process that encourages active participation and market-driven outcomes.

## Liquidation Trigger Conditions

Liquidation is triggered if, by the end of the auction, the cumulative bids on the side favoring liquidation exceed those on the opposing side. If the auction concludes without favoring liquidation, no liquidation occurs, and the auction closes as follows:

- If Liquidation Bids Win: The collateral is liquidated, and the participant with the highest repay value receives the collateral, while the losing side’s bets are forfeited and distributed among the winning side proportionally to their bet contributions.
- If Anti-Liquidation Bids Win: No liquidation occurs. The winning side receives back their bets, while the losing side forfeits their bets, which are distributed to the winning participants based on the proportion of their contributions.

This mechanism ensures that liquidation only takes place when deemed necessary by market participants, with transparent and open bidding determining the outcome.

# Redemption Auction Mechanism

In addition to the existing borrowing and liquidation features, LiquidAX introduces a redemption auction mechanism. This new mechanism allows stablecoin holders to redeem their stablecoins for collateral in a decentralized and market-driven manner.

## User-Defined Origination Fees

Borrowers can now specify their own origination fees when locking collateral into the LiquidAX protocol, with a minimum baseline set by the system. These origination fees influence the redemption process, as users with lower origination fees have their collateral prioritized for redemption. This feature encourages borrowers to compete by setting lower fees, benefiting the entire protocol by providing a more efficient collateral management system.

## Redemption Auction Process

### Auction Initiation:

Any user holding LiquidAX stablecoins can initiate a redemption auction by specifying a baseline price for the collateral in terms of stablecoins.
This baseline price serves as the starting bid for the auction.

### Bidding Process:

Participants can place bids higher than the baseline price, reflecting their perception of the collateral’s value relative to the market.
The auction remains open until there is a 15-minute period of inactivity, after which the highest bid is deemed the winner.

### Redemption Execution:

Once the auction concludes, all redeemers exchange their stablecoins for the collateral at the winning bid price.
The collateral corresponding to the redeemers' stablecoins is selected based on the lowest origination fees set by borrowers.

### Fee Structure:

Redeemers pay a redemption fee based on the difference between their bid and the winning bid. The closer the bid is to the final market-driven price, the lower the fee.
A portion of these fees is redistributed to the Stability Pool to incentivize staking and provide liquidity to the protocol.

# Economic Incentives

## Borrowers

- Borrowers are incentivized to maintain an appropriate collateralization ratio, as liquidations are only triggered when there is significant market consensus. The one-hour delay allows borrowers to reassess their positions before potential liquidation.
- Borrowers are incentivized to set competitive origination fees, as collateral with the lowest fees will be prioritized in redemption events.
- Borrowers benefit from a no-interest model, with only a one-time origination fee, updatable based on market conditions, making this a cost effective alternative for borrowers.

## Dealers

Dealers are motivated to monitor borrowing positions and trigger liquidation auctions when necessary. By participating in the auction process, dealers play a crucial role in maintaining the stability of the protocol.

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

LiquidAX revolutionizes stablecoin issuance through its oracle-free, auction-driven processes, including redemption, liquidation, and borrowing. The introduction of user-defined origination fees and a redemption auction allows participants to redeem stablecoins for collateral in a decentralized and market-efficient manner. By aligning incentives across all participants and eliminating reliance on external oracles, LiquidAX creates a resilient, secure, and adaptable stablecoin protocol. This ensures a decentralized financial ecosystem where the community drives outcomes, contributing to a more stable and fair DeFi landscape.
