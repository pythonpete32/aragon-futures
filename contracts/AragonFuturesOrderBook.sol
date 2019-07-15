pragma solidity ^0.4.24;
/*
  In this implimentation, futures contracts are not fungible.
  order creator selects expiry time
  Contract closes one hour after expiry
*/


import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";

contract AragonFuturesOrderBook {
  using SafeMath for uint256;

  // still need to add ANT and DAI tokens how do i do that

  struct Order {
    uint id;
    State state;
    address buyer;
    address seller;
    uint antAmmount;
    uint daiAmmount;
    uint antDeposit;
    uint daiDeposit;
    uint expiryTime;
    uint closeTime;
  }

  enum State {
    OPEN, FILLED, EXPIRED, CLOSED
  }

  mapping (uint => Order) public orderBook;
  mapping (address => mapping (uint => Order)) public orders;
  uint nextOrderId;
  address owner;

  event CreateBuyOrder(address maker, uint buyAmmount, uint sellAmmount, uint expiry)

  // the constructor needs to create refrence to ANT and DAI
  constructor () public {
    owner = msg.sender;
    nextOrderId = 0;
  }

  function createBuyOrder(uint _buyAmmount, uint _sellAmmount, uint _deposit, uint _expiry) external payable{
    // what require statements do i need here
    Order storage newOrder = orderBook[nextOrderId];
    orderBook[nextOrderId].id = nextOrderId;
    orderBook[nextOrderId].state = State.OPEN;
    orderBook[nextOrderId].buyer = msg.sender;
    orderBook[nextOrderId].antAmmount = _buyAmmount;
    orderBook[nextOrderId].daiAmmount = _sellAmmount;
    orderBook[nextOrderId].antDeposit = _deposit;
    orderBook[nextOrderId].expiryTime = now + _expiry;
    orderBook[nextOrderId].closeTime = orderBook[nextOrderId].expiryTime + 3600 // 1 hour

    orders[msg.sender][nextOrderId] = newOrder;
    emit CreateBuyOrder(msg.sender, _buyAmmount, _sellAmmount, _expiry);
    nextOrderId ++;
  }

  function createSellOrder() external payable{}

  function fillOrder() external payable{}

  function transferContract()external {}

  function cancelOrder() external{}

  function completeOrder() external payable{}

  function claimTokens() external payable{}

  function claimDeposit() external payable{}

  function getOrders() external view {}

  function _transitionState() internal{}
}
