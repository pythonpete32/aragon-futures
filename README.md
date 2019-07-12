# Aragon Futures

allows users to speculate on the future price of ANT with leverage and without any counterparty risk.

## Why

giving market makers the ability to go short on a asset

## 0.1

in the basic iteration

### Specification

(i < y < z) (x, y, i) is determined by seller at time of posting offer m = 0.5 * x o =

1. seller posts offer to:

  - sell w ANT
  - for x rate
  - at y block
  - until i block
  - deposits m collateral

2. buyer lifts offer:

  - deposits m collateral

3. at block y both buyer and seller have until block z to meet their obligation o

  - if either party defaults, they loose their deposit to the counter party
  - if both default, they can both withdraw their deposits

## 1.0

in the final iteration

### Specification

buyer and seller obligation are transferable (i < y < z) x = spot price at y (this dpsnt make sence, this is the price at expiry and used to calculate both parties obligation) y = fixed time in future i = fixed time in future m = 0.5 * x
