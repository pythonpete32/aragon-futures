# Aragon Futures

Allows users to speculate long or short on the future price of ANT with leverage and without any counterparty risk. 

##### Why

giving market makers the ability to go short on an asset allows them to hedge there risk, earn fixed income and thus offer more liquidity to ANT without exposing themselves to counterparty risk

##### Limitations
can not expect to earn more than 100% ROI as counterparty has no incentive to fulfil obligation if the underlying price at expiry is greater than 50% of the 

##### Advantages 
in the final iteration
- Contracts are fungible allowing futures to be tradeable on secondary markets. 
- creates an arbitrage opportunity to exploit price dislocations
- possible to have dao own the smart contracts and introduce fees in exchange for maintaining a front end 

## Version 0.1

- in the basic iteration, a seller posts a sell order in the order book and specifies:
1.  how much ANT he is willing to sell
2.  at what price
3. at what time in the future (1 day, 7, days, 1 month) 
4. And how long the offer will last
He also deposits 50% of the offer as collateral 
- a buyer accepts the offer and deposits 50% of the offer in DAI
- At the expiry of the contract, both parties have an hour to deposit their outstanding balance 
- if either side fail to do so they lose their collateral 
- if both fail to do so they can claim their deposit back

### Specification

* (i < y < z) 
* (x, y, i) is determined by seller at time of posting offer
* m = 0.5 * x 
* o = 0.5 * x
* z = y + 240 blocks

1. seller posts offer to:

  - sell w ANT
  - at x rate
  - at y block
  - until i block
  - deposits m collateral


2. buyer lifts offer:

  - deposits m collateral

3. at block y both buyer and seller have until block z to meet their obligation o

  - if either party defaults, they lose their deposit to the counterparty
  - if both default, they can both withdraw their deposit 

#### Cases

###### case 1

###### case 2

###### case 3

## Version 1.0

- In the final iteration buyers and sellers and post bid and asks on an order book or lift and hit orders on the order book and specifies:
1.  how much ANT he is willing to sell or buy
2.  at what price
3. at what time in the future (1 day, 7, days, 1 month) 
4. And how long the offer will last
He
5. deposits 50% of the offer as collateral 
- a buyer/seller accepts the offer and deposits 50% of the offer
- At the expiry of the contract, both parties have an hour to deposit their outstanding balance 
- if either side fail to do so they lose their collateral 
- if both fail to do so they can claim their deposit back


### Specification

* buyer and seller obligation are transferable tokens 
* (i < y < z) 
* x =  orderbook matching engine
* y = fixed time in future 
* i = fixed time in future 
* m = 0.5 * x
* o = spot at y - m
* z = y + 240 blocks

1. Buyer/seller posts bid/offer to:

  - sell/buy w ANT
  - at x rate
  - at y block
  - until i block
  - deposits m collateral


2. buyer/seller lifts/hits offer:

  - deposits m collateral

3. at block y both buyer and seller have until block z to meet their obligation o

  - if either party defaults, they lose their deposit to the counterparty
  - if both default, they can both withdraw their deposit 

#### Cases

###### case 1

###### case 2

###### case 3
