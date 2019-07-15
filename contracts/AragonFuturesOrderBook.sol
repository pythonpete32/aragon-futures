pragma solidity ^0.4.24;
/*
  In this implimentation, futures contracts are not fungible.
  order creator selects expiry time
  Contract closes one hour after expiry
*/

import "@aragon/os/contracts/apps/AragonApp.sol";
import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";

contract AragonFuturesOrderBook is AragonApp {
  using SafeMath for uint256;

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

  constructor () public {
    owner = msg.sender;
  }

  function createBuyOrder() external payable{}

  function createSellOrder() external payable{}

  function fillOrder() external payable{}

  function transferContract()external {}

  function cancelOrder() external{}

  function completeOrder() external payable{}

  function claimTokens() external payable{}

  function claimDeposit() external payable{}

  function _transitionState() internal{}
}
