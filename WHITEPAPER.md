                                            LiquidAX - A Decentralized, Oracle-Free Stablecoin Protocol
                                                      Gopalakrishnan G<gopalakrishnan.g@gov.in>

# Abstract

LiquidAX is a decentralized, oracle-free stablecoin protocol enabling users to borrow stablecoins against collateral under user-defined conditions. The protocol features a unique liquidation auction mechanism driven by market participants, ensuring that liquidations only occur when deemed necessary by the community, instead of by the external oracle. Auctions conclude after an hour of inactivity, with borrowers able to abort the process by adjusting their collateral or repaying debt. LiquidAX charges no interest, opting for a one-time origination fee of 0.5%. The protocol adapts to all market conditions by adjusting collateral requirements and stablecoin value, serving as a dynamic alternative to traditional interest rates. Additionally, the Stability Pool allows users to stake stablecoins, earn rewards from origination fees, and participate in liquidation auctions. By eliminating reliance on external oracles and utilizing a user-driven auction system, LiquidAX ensures a secure, decentralized, and efficient stablecoin ecosystem.

# Introduction

Stablecoins are crucial to the decentralized finance (DeFi) ecosystem, offering stability in a highly volatile cryptocurrency environment. Many existing stablecoin protocols depend on external price oracles to manage collateral value, which introduces centralization risks and potential vulnerabilities. LiquidAX provides a fully decentralized, oracle-free stablecoin protocol, utilizing a user-driven liquidation auction system where participants decide the outcome based on open bids, ensuring fairness and resilience. LiquidAX does not impose an interest rate on borrowed stablecoins, making it a more affordable and predictable option for users. The protocol also operates effectively across all market conditions by adjusting collateral requirements and the value of the stablecoin, which serves as a dynamic alternative to traditional interest rate adjustments. Additionally, the Stability Pool mechanism enhances the protocol by allowing users to stake their stablecoins, earn rewards, and participate in liquidation auctions, further contributing to the system's stability and efficiency.

# Oracle-Free Stability: A Key Feature

LiquidAX’s oracle-free architecture is a defining feature. Traditional stablecoin protocols often rely on external oracles to determine collateral value, creating risks such as manipulation and centralization. LiquidAX circumvents these issues by relying solely on on-chain auction mechanisms, where users' open bids determine the need for liquidation. This decentralized process strengthens the protocol’s security and user trust.

# Overview of LiquidAX Protocol

LiquidAX allows users to borrow stablecoins by locking collateral tokens into the protocol. The system avoids external oracles, instead employing a market-driven auction mechanism to decide if and when liquidation should occur. This design ensures that liquidation only happens when the community deems it necessary. Additionally, LiquidAX does not charge interest on borrowed amounts, distinguishing it from other stablecoin protocols that often impose ongoing interest fees.

## Borrowing Mechanism

### Borrowing Conditions

Users initiate borrowing by locking collateral tokens into the LiquidAX smart contract, specifying:

- Collateral Amount: The amount of collateral token deposited.
- Borrow Amount: The amount of stablecoins the user wishes to borrow.
- Origination Fee: A one-time fee of 0.5% of the borrowed amount, paid upfront.

Borrow requests are organized in a list ordered based on the borrow-to-collateral ratio, prioritizing more collateralized positions for later liquidation.

Another list maintains borrowings that need clearance through the Liquidation Auction mechanism.

###Borrowing Delay and Withdrawal
After submitting a borrow request, the user must wait to withdraw stablecoins. During this time, the borrowing is subject to a potential liquidation auction. If no auction is triggered, or if the auction does not result in liquidation, the user can withdraw their stablecoins after the waiting period. Importantly, users incur no interest charges during this waiting period or at any time during the life of the loan.

###Market Condition Adaptation
LiquidAX is designed to operate effectively in all market conditions. The protocol adapts by varying the collateral requirements and the price of the stablecoin, which serves as a proxy for traditional interest rates:

- High Interest Rate Environments: As interest rates in the broader market rise, LiquidAX increases the collateral requirements for borrowing. This higher collateral ratio compensates for the increased cost of capital, maintaining the stability of the system.
- Low or Negative Interest Rate Environments: Conversely, in scenarios where interest rates are low or negative, LiquidAX decreases the collateral requirements. This is achieved by adjusting the price of the stablecoin relative to fiat, making it more favorable for borrowers while still ensuring the protocol’s security.

LiquidAX does not target a specific value for the stablecoin; instead, the stablecoin’s value is determined by market conditions and is dynamically adjusted through the collateral ratio and liquidation threshold. This approach ensures that the protocol remains resilient and responsive to varying economic conditions.

## Stability Pool

The Stability Pool is a key component of LiquidAX, designed to enhance the protocol's stability and provide additional incentives for participants.

### Stability Pool Mechanics

Users can stake their stablecoins in the Stability Pool, earning rewards in the form of a portion of the origination fees collected by the protocol. These rewards are distributed proportionally to the amount staked by each participant.

### Participation in Liquidation Auctions

The Stability Pool also plays a crucial role in liquidation auctions by providing liquidity. During a liquidation auction, users can borrow stablecoins from the Stability Pool to place their bids. This borrowed amount is subject to a fee of 10% of the winning bet proceeds, which is paid to the Stability Pool. The remaining 90% of the discounted collateral from the liquidation is distributed to the Stability Pool participants, while the remaining 10% is awarded to the user who placed the winning bet.

- Borrowing from the Stability Pool: Users borrowing stablecoins from the Stability Pool during a liquidation auction pay a fee equal to 10% of the winning bet proceeds. This fee is directed back to the Stability Pool, benefiting all stakers.
- Collateral Distribution: After a successful liquidation, 90% of the discounted collateral is distributed among the Stability Pool participants based on their stakes, while the remaining 10% is given to the user who placed the winning bid.

###Strategic Importance
The Stability Pool not only provides liquidity for liquidation auctions but also creates a mechanism for stablecoin holders to earn passive income. By staking their stablecoins, users contribute to the overall stability of the protocol while benefiting from the system's fees and liquidation processes.

## Liquidation Auction Mechanism

### Role of the Dealer

To initiate a liquidation auction, LiquidAX introduces the "dealer" concept. The dealer is a user who triggers the auction during the one-hour delay before stablecoin withdrawal or when the collateralization ratio falls near or below the liquidation threshold.

### Triggering a Liquidation Auction

During the one-hour delay, the dealer can trigger a liquidation auction by placing an open bid. Unlike traditional systems where stablecoins are used for bidding, LiquidAX requires bets to be placed in ETH or the native currency of the blockchain.

### Auction Bidding Process

Other users can join the auction by placing their own open bids, specifying a repay value and bet. The auction remains open and allows additional bids as long as new bets are placed within one hour of the last bet on either side.

- Auction Duration: The auction concludes if there are no new bets placed on either side for one hour. If bets continue to increase on only one side, the auction will still conclude based on the time of the earliest remaining bet on that side. This ensures that the auction’s duration is influenced by the activity on both sides and prevents indefinite extensions due to one-sided activity.
- Bid Incrementation: Participants cannot revise their bets once submitted. However, they can increase their bets during the auction by placing additional bids on their chosen side, which can influence the outcome and strengthen their position.
- Real-Time Repayment Decisions: During the auction, participants on the winning side have the option to repay the debt in real-time, depending on the market conditions and their assessment of the collateral’s value. This flexibility allows participants to act decisively when it makes the most economic sense to do so.
  -Bid: The amount of ETH(or native currency) the user is willing to risk during the auction process. This bet represents the commitment to either repay the debt (if the auction favors liquidation) or contribute to the pool opposing liquidation. The bets determine the participants' stakes in the outcome of the auction.

This structure ensures that the auction has a definitive endpoint determined by overall activity, with strategic considerations given to both sides. The auction’s conclusion is dynamic, allowing for a responsive and fair process that encourages active participation and market-driven outcomes.

## Liquidation Trigger Conditions

Liquidation is triggered if, by the end of the auction, the cumulative bids on the side favoring liquidation exceed those on the opposing side. If the auction concludes without favoring liquidation, no liquidation occurs, and the auction closes as follows:

- If Liquidation Bids Win: The collateral is liquidated, and the participant with the highest repay value receives the collateral, while the losing side’s bets are forfeited and distributed among the winning side proportionally to their contributions. The Stability Pool receives 90% of the discounted collateral, while the remaining 10% goes to the user who placed the winning bet.
- If Anti-Liquidation Bids Win: No liquidation occurs. The winning side receives back their bets, while the losing side forfeits their bets, which are distributed to the winning participants based on the proportion of their contributions.

This mechanism ensures that liquidation only takes place when deemed necessary by market participants, with transparent and open bidding determining the outcome.

# Economic Incentives

## Borrowers

Borrowers are incentivized to maintain an appropriate collateralization ratio, as liquidations are only triggered when there is significant market consensus. The one-hour delay allows borrowers to reassess their positions before potential liquidation. Additionally, the absence of interest rates makes LiquidAX a more predictable and cost-effective borrowing option.

## Dealers

Dealers are motivated to monitor borrowing positions and trigger liquidation auctions when necessary. By participating in the auction process, dealers play a crucial role in maintaining the stability of the protocol.

## Stability Pool Participants

Participants in the Stability Pool are encouraged to stake their stablecoins to earn a share of the origination fees and liquidation proceeds. This dual incentive structure makes staking in the Stability Pool an attractive option for users looking to passively earn rewards while contributing to the protocol’s overall stability.

## Auction Participants

Participants are encouraged to place strategic bids, as they can profit from successful liquidation by being on the winning side. The protocol’s design ensures that liquidations are aligned with real market conditions, rewarding participants who contribute to accurate price discovery.

# Risk Management

LiquidAX integrates several risk mitigation mechanisms:

- Overcollateralization: Borrow requests are ranked by collateralization ratios, ensuring that highly collateralized positions are less vulnerable to liquidation.
- Dynamic Auction Threshold: The protocol can adjust the liquidation threshold based on market conditions, maintaining stability.
- Delayed Withdrawals: The one-hour delay between borrowing and withdrawal provides a buffer period for market participants to evaluate and act on potential liquidation risks.
  -Stability Pool: The Stability Pool acts as a buffer during liquidation events, providing liquidity and absorbing potential shocks to the system.

# Oracle-Free Architecture

LiquidAX’s reliance on on-chain auctions removes the need for price oracles, which are common points of vulnerability in other DeFi protocols. By allowing users to determine the value of collateral through open bids, LiquidAX avoids the risks associated with external data sources, such as manipulation or failure.

## On-Chain Market Forces

The protocol is driven by market participants who determine the value of collateral and debt through competitive bidding. This on-chain mechanism ensures that all decisions are decentralized and reflect the collective judgment of the network’s users.

## Decentralized Auction Mechanism

The decentralized auction process ensures that liquidation decisions are made transparently and fairly, without relying on external inputs. This not only enhances security but also increases trust in the protocol’s ability to manage collateral effectively.

# Governance and Future Development

LiquidAX is a decentralized protocol, with no central governance or governance token.

# Conclusion

LiquidAX revolutionizes stablecoin issuance through its oracle-free, auction-driven liquidation process. By allowing users to determine collateral outcomes via open bids, the protocol ensures fairness, decentralization, and stability. The absence of an interest rate, combined with a one-time origination fee, makes LiquidAX a cost-effective solution for borrowers. The Stability Pool provides an additional layer of stability and rewards for participants, ensuring liquidity during liquidation events and offering passive income opportunities. The dealer mechanism, combined with rules that conclude the auction after an inactivity period, prevents unnecessary liquidations and ensures that market-driven decisions prevail. Additionally, LiquidAX’s ability to adapt to varying market conditions by adjusting the value of the stablecoin and collateral requirements provides a dynamic alternative to traditional interest rate adjustments. LiquidAX empowers participants to maintain a stable and decentralized financial ecosystem, aligning incentives for borrowers, dealers, and auction participants.
