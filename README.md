# README

# Aragon Futures

Allows users to speculate long or short on the future price of ANT with leverage and without any counterparty risk.

## Why

giving market makers the ability to go short on an asset allows them to hedge there risk, earn fixed income and thus offer more liquidity to ANT without exposing themselves to counterparty risk

## Context

**Alice** is a market maker providing liquidity for ANT on 0x protocol. She uses her inventory of ANT to earn the bid-ask spread. Alice has no opinion on the future price of ANT she simply wants to remain delta neutral on her inventory of ANT (i.e. she wants the value of her ANT to remain the same in relation to DAI)

**Bob** is a trader, he believes ANT is undervalued and is about to start a massive bull run. He has an inventory of DAI he uses to make speculative trades

1. On the 1st of July, **Alice** buys 1,000 ANT at 10 DAI per token
2. She immediately places a sell order for 1,000 ANT at 11 DAI (expiring on the 1st of August) on the Aragon futures exchange. depositing 500 ANT as collateral
3. **Bob** sees the futures order, even though the price is 10% higher than the spot price (today's price), he thinks the price will be much higher by 1st August, he doesn't want to lock up all his DAI buying at spot, so he is happy to buy the futures contract.
4. **Bob** buys the 1,000 ANT futures contracts depositing 5,500 DAI as collateral
5. At this point, **Alice** has locked in 1,000 DAI profit and she has 500 ANT inventory to trade with. **Bob** has locked in a price of 11 DAI and has 5,500 DAI to trade with **
6. On the 1st of August, the spot price of ANT is 14 DAI. The value of the **Alice** ANT is now 14,000 DAI however she has promised to sell it to **Bob** at 11,000 DAI. She now has 12 hours to send the rest of the ANT to futures exchange contract or she will forfeit the collateral and the claim on the DAI. She sends the remaining 500 ANT.
7. **Bob** sends 5,500 DAI to fulfil his obligation. During the month he made an additional 3,000 DAI trading with the this 5,500 DAI which offset the 1,000 DAI premium he paid for the futures contract
8. Both **Alice** and **Bob** withdraw their purchases from the exchange
9. **Alice** is happy. She made a profit and hedged her risk
10. **Bob** is happy he made a bigger profit than he would have simply bought at spot

## Use case

- User can place an order on the order book to buy or sell ant for DAI
- User can fill orders on the order book
- User can cancel an unfilled order
- User can send the due balance to contract at expiry
- User can withdraw purchase after order closes
- User can claim the deposit back if both parties fail to pay the due balance
- User can transfer the contract to another address

### Limitations

- can not expect to earn more than 100% ROI as counterparty has no incentive to fulfil obligation if the underlying price at expiry is greater than 50% of the
- As the future price is determined upfront, futures contracts are not fungible. In a later iteration, this will be fixed by having settlement = spot at future expiry. This requires an oracle and this adds a bit of complexity

### Advantages

in the final iteration

- Possible to have DAO own the smart contracts and introduce fees in exchange for maintaining a front end

## Version 0.1

- in the first iteration, a seller/buyer posts a sell/buy order in the order book and specifies:
- how much ANT he is willing to sell/buy
- at what price
- the expiry is fixed as a state variable in the contract constructor
- all futures in the contract expire at the same time
- a buyer accepts the offer and deposits 50% of the offer in DAI
- At the expiry of the contract, both parties have an hour to deposit their outstanding balance
- if either side fail to do so they lose their collateral
- if both fail to do so they can claim their deposit back

### Specification

- (`i` < `y` < `z`)
- (`x`, `y`) is determined by the seller/buyer at the time of posting offer
- `m` = 0.5 * `x`
- `o` = 0.5 * `x`
- `z` = `y` + 240 blocks
- seller/buyer posts offer to:
- sell/buy `w` ANT
- at `x` rate
- at `y` block
- deposits m collateral
- buyer/seller lifts/hits offer:
- deposits `m` collateral
- at block y both buyer and seller have until block `z` to meet their obligation `o`
- if either party defaults, they lose their deposit to the counterparty
- if both default, they can both withdraw their deposit
