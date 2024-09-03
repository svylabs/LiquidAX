                                            LiquidAX - A Decentralized, Oracle-Free Stablecoin Protocol

# Abstract

LiquidAX is a decentralized, oracle-free stablecoin protocol that enables users to borrow stablecoins against specific collateral tokens under user-defined conditions. The protocol introduces a liquidation auction mechanism where users place open bids, creating a transparent, market-driven process to determine the necessity of liquidation. By eliminating reliance on external oracles and incorporating a dealer mechanism to initiate auctions, LiquidAX ensures a secure, decentralized, and efficient liquidation process. Liquidation occurs only if the auction concludes with bids favoring liquidation. The auction concludes when no new bids are placed for a one-hour period after the last bid. Borrowers have the right to adjust their collateral ratio during the auction, which can abort the auction. This document details the core principles and mechanisms that drive LiquidAX.

# Introduction

Stablecoins are crucial to the decentralized finance (DeFi) ecosystem, offering stability in a highly volatile cryptocurrency environment. Many existing stablecoin protocols depend on external price oracles to manage collateral value, which introduces centralization risks and potential vulnerabilities. LiquidAX provides a fully decentralized, oracle-free stablecoin protocol, utilizing a user-driven liquidation auction system where participants decide the outcome based on open bids, ensuring fairness and resilience.

# Oracle-Free Stability: A Key Feature

LiquidAX’s oracle-free architecture is a defining feature. Traditional DeFi protocols often rely on external oracles to determine collateral value, creating risks such as manipulation, latency, and centralization. LiquidAX circumvents these issues by relying solely on on-chain auction mechanisms, where users' open bids determine the need for liquidation. This decentralized process strengthens the protocol’s security and user trust.

# Overview of LiquidAX Protocol

LiquidAX allows users to borrow stablecoins by locking collateral tokens into the protocol. The system avoids external oracles, instead employing a market-driven auction mechanism to decide if and when liquidation should occur. This design ensures that liquidation only happens when the community deems it necessary.

## Borrowing Mechanism

### Borrowing Conditions

Users initiate borrowing by locking collateral tokens into the LiquidAX smart contract, specifying:

- Collateral Amount: The amount of collateral token deposited.
- Borrow Amount: The amount of stablecoins the user wishes to borrow.
- Initial Liquidation Auction Fee: A fee (in collateral) paid upfront for a potential liquidation auction, enabling less waiting time for stablecoin withdrawal.

Borrow requests are organized in a list ordered based on the borrow-to-collateral ratio, prioritizing more collateralized positions for later liquidation.

Another list maintains a list of borrowings that need clearance through the Liquidation Auction mechanism.

### Borrowing Delay and Withdrawal

After submitting a borrow request, the user must wait to withdraw stablecoins. During this time, the borrowing is subject to a potential liquidation auction. If no auction is triggered, or if the auction does not result in liquidation, the user can withdraw their stablecoins after the waiting period.

## Liquidation Auction Mechanism

### Role of the Dealer

To initiate a liquidation auction, LiquidAX introduces the "dealer" concept. The dealer is a user who triggers the auction during the one-hour delay before stablecoin withdrawal. The dealer is incentivized by potentially receiving a dealer fee from other auction participants.

- Dealer Fee: A fixed amount of collateral paid by all auction participants. The dealer receives this fee only if their bet is on the winning side of the auction and they are not the sole participant.

### Triggering a Liquidation Auction

During the one-hour delay, the dealer can trigger a liquidation auction by placing an open bid, including:

- Repay Value: The amount of stablecoins the dealer is willing to repay for the borrower's collateral.
- Bet: The amount of stablecoins the user is willing to risk during the auction process.
- Dealer Fee Contribution: The dealer also contributes their own dealer fee.

### Auction Bidding Process

Other users can join the auction by placing their own open bids, specifying a repay value, bet, and the dealer fee. The auction remains open and allows additional bids as long as new bets are placed within one hour of the last bet on either side.

- Auction Duration: The auction concludes if there are no new bets placed on either side for one hour. If bets continue to increase on only one side, the auction will still conclude based on the time of the earliest remaining bet on that side. This ensures that the auction’s duration is influenced by the activity on both sides and prevents indefinite extensions due to one-sided activity.
- Bid Incrementation: Participants cannot revise their bets once submitted. However, they can increase their bets during the auction by placing additional bids on their chosen side, which can influence the outcome and strengthen their position.
- Real-Time Repayment Decisions: During the auction, participants on the winning side have the option to repay the debt in real-time, depending on the market conditions and their assessment of the collateral’s value. This flexibility allows participants to act decisively when it makes the most economic sense to do so.
- Bid: The amount of stablecoins the user is willing to risk during the auction process. This bet represents the commitment to either repay the debt (if the auction favors liquidation) or contribute to the pool opposing liquidation. The bets determine the participants' stakes in the outcome of the auction.

This structure ensures that the auction has a definitive endpoint determined by overall activity, with strategic considerations given to both sides. The auction’s conclusion is dynamic, allowing for a responsive and fair process that encourages active participation and market-driven outcomes.

### Liquidation Trigger Conditions

Liquidation is triggered if, by the end of the auction, the cumulative bids on the side favoring liquidation exceed those on the opposing side. If the auction concludes without favoring liquidation, no liquidation occurs, and the auction closes as follows:

- If Liquidation Bids Win: The collateral is liquidated, and the participant with the highest repay value receives the collateral, while the losing side’s bets are forfeited and distributed among the winning side proportionally to their contributions.
- If Anti-Liquidation Bids Win: No liquidation occurs. The winning side receives back their bets and fees, while the losing side forfeits their bets, which are distributed to the winning participants based on the proportion of their contributions.
  This mechanism ensures that liquidation only takes place when deemed necessary by market participants, with transparent and open bidding determining the outcome.

## Dealer Compensation and Fairness

- Dealer Fee Conditions: The dealer receives the dealer fee only if their bid is on the winning side of the auction and there are other participants. If the dealer’s bid is on the losing side, they forfeit their bet and do not receive any dealer fees.
- Minimum Participation: The auction must have at least two participants (including the dealer) for the dealer to be eligible for the fee. This ensures that no single participant can dominate or manipulate the auction process.

# Economic Incentives

## Borrowers

Borrowers are incentivized to maintain an appropriate collateralization ratio, as liquidations are only triggered when there is significant market consensus. The one-hour delay allows borrowers to reassess their positions before potential liquidation.

## Dealers

Dealers are motivated to monitor borrowing positions and trigger liquidation auctions when necessary. By tying dealer compensation to the auction's outcome and requiring multiple participants, the protocol ensures that dealers act in the best interest of the market.

## Auction Participants

Participants are encouraged to place strategic bids, as they can profit from successful liquidation by being on the winning side. The protocol’s design ensures that liquidations are aligned with real market conditions, rewarding participants who contribute to accurate price discovery.

# Risk Management

LiquidAX integrates several risk mitigation mechanisms:

- Overcollateralization: Borrow requests are ranked by collateralization ratios, ensuring that highly collateralized positions are less vulnerable to liquidation.
- Dynamic Auction Threshold: The protocol can adjust the liquidation threshold based on market conditions, maintaining stability.
- Delayed Withdrawals: The one-hour delay between borrowing and withdrawal provides a buffer period for market participants to evaluate and act on potential liquidation risks.

# Oracle-Free Architecture

LiquidAX’s reliance on on-chain auctions removes the need for price oracles, which are common points of vulnerability in other DeFi protocols. By allowing users to determine the value of collateral through open bids, LiquidAX avoids the risks associated with external data sources, such as manipulation or failure.

## On-Chain Market Forces

The protocol is driven by market participants who determine the value of collateral and debt through competitive bidding. This on-chain mechanism ensures that all decisions are decentralized and reflect the collective judgment of the network’s users.

## Decentralized Auction Mechanism

The decentralized auction process ensures that liquidation decisions are made transparently and fairly, without relying on external inputs. This not only enhances security but also increases trust in the protocol’s ability to manage collateral effectively.

# Governance and Future Development

LiquidAX is a decentralized protocol, with no actors.

## Conclusion

LiquidAX revolutionizes stablecoin issuance through its oracle-free, auction-driven liquidation process. By allowing users to determine collateral outcomes via open bids, the protocol ensures fairness, decentralization, and stability. The dealer mechanism, combined with rules that conclude the auction after an inactivity period, prevents unnecessary liquidations and ensures that market-driven decisions prevail. LiquidAX empowers participants to maintain a stable and decentralized financial ecosystem, aligning incentives for borrowers, dealers, and auction participants.

Feedback on the Name "LiquidAX"
The name "LiquidAX" is strong and conveys the key concepts behind the protocol:

"Liquid" suggests liquidity and the process of liquidation, which are central to the protocol's functionality.
"AX" gives the name a modern, tech-savvy edge, making it memorable and aligning with the branding of other successful DeFi protocols.
Overall, "LiquidAX" is a suitable and marketable name that effectively communicates the core functionality and purpose of the protocol.
