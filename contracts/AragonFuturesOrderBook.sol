pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;
/*
  In this implimentation, futures contracts are not fungible.
  - order creator selects expiry time
  - Contract closes one hour after expiry
  
  TODO:
  - impliment state transition function
        - state transition function should run after every interaction and update the state of the order
  - refactor buy/sell & fillBuy/fillSell so there are only 2 functions instead of 4
  - refactor require functions as modifiers
*/


import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";
import "../node_modules/zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "../node_modules/zeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";

contract AragonFuturesOrderBook {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  string private constant ERROR_NOT_OWNER_OF_CONTRACT = "NOT_OWNER_OF_CONTRACT";
  string private constant ERROR_ORDER_DOSE_NOT_EXIST = "ORDER_DOSE_NOT_EXIST";
  string private constant ERROR_ORDER_IS_NOT_OPEN = "ORDER_IS_NOT_OPEN";
  string private constant ERROR_ORDER_CLOSED = "ORDER_CLOSED";
  string private constant ERROR_ORDER_HAS_EXPIRED = "ORDER_HAS_EXPIRED";
  string private constant ERROR_INSUFFICIENT_FUNDS = "INSUFFICIENT_FUNDS";
  string private constant ERROR_INCORRECT_DEPOSIT_VALUE = "INCORRECT_DEPOSIT_VALUE";
  string private constant ERROR_PAYMENT_WINDOW_NOT_REACHED = "PAYMENT_WINDOW_NOT_REACHED";


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

  enum State {OPEN, FILLED, EXPIRED, CANCELED}
  enum Type {BUY, SELL}
  ERC20 ANT;
  ERC20 DAI;
  mapping (uint => Order) public orderBook;
  mapping (address => mapping (uint => Order)) public orders;
  uint nextOrderId;

  event CreateBuyOrder(uint id, address maker, uint buyAmmount, uint sellAmmount, uint expiry);
  event CreateSellOrder(uint id, address maker, uint buyAmmount, uint sellAmmount, uint expiry);
  event FillBuyOrder(uint id, address taker);
  event FillSellOrder(uint id, address taker);

  constructor () public {
    nextOrderId = 0;
		ANT = ERC20(0x0D5263B7969144a852D58505602f630f9b20239D); // rinkeby
		DAI = ERC20(0x0527E400502d0CB4f214dd0D2F2a323fc88Ff924); // rinkeby
  }

  /*
  *
  */
  function createBuyOrder(
    uint _buyAmmount,
    uint _sellAmmount,
    uint _deposit,
    uint _expiry
    )
    external
    payable
    {
    require(DAI.balanceOf(msg.sender) > _sellAmmount, ERROR_INSUFFICIENT_FUNDS); // require msg.sender has enough DAI
    require(_deposit == _buyAmmount.div(2), ERROR_INCORRECT_DEPOSIT_VALUE);

    DAI.safeTransferFrom(msg.sender, this, _deposit);
    Order storage newOrder = orderBook[nextOrderId];
    orderBook[nextOrderId].id = nextOrderId;
    orderBook[nextOrderId].state = State.OPEN;
    orderBook[nextOrderId].buyer = msg.sender;
    orderBook[nextOrderId].antAmmount = _buyAmmount;
    orderBook[nextOrderId].daiAmmount = _sellAmmount;
    orderBook[nextOrderId].daiDeposit = _deposit;
    orderBook[nextOrderId].expiryTime = now + _expiry;
    orderBook[nextOrderId].closeTime = orderBook[nextOrderId].expiryTime + 3600; // 1 hour

    orders[msg.sender][nextOrderId] = newOrder;
    emit CreateBuyOrder(nextOrderId, msg.sender, _buyAmmount, _sellAmmount, _expiry);
    nextOrderId ++;
  }

  /*
  *
  */
  function createSellOrder(
    uint _buyAmmount,
    uint _sellAmmount,
    uint _deposit,
    uint _expiry
  )
    external
    payable
    {
    require(ANT.balanceOf(msg.sender) > _sellAmmount, ERROR_INSUFFICIENT_FUNDS); // require msg.sender has enough ANT
    require(_deposit == _sellAmmount.div(2), ERROR_INCORRECT_DEPOSIT_VALUE);

    ANT.safeTransferFrom(msg.sender, this, _deposit);
    Order storage newOrder = orderBook[nextOrderId];
    orderBook[nextOrderId].id = nextOrderId;
    orderBook[nextOrderId].state = State.OPEN;
    orderBook[nextOrderId].seller = msg.sender;
    orderBook[nextOrderId].daiAmmount = _buyAmmount;
    orderBook[nextOrderId].antAmmount = _sellAmmount;
    orderBook[nextOrderId].antDeposit = _deposit;
    orderBook[nextOrderId].expiryTime = now + _expiry;
    orderBook[nextOrderId].closeTime = orderBook[nextOrderId].expiryTime + 3600; // 1 hour
    orders[msg.sender][nextOrderId] = newOrder;
    
    emit CreateSellOrder(nextOrderId, msg.sender, _buyAmmount, _sellAmmount, _expiry);
    nextOrderId ++;
  }

  /*
  *
  */
  function fillBuyOrder(uint _orderId, uint _deposit) external payable{
    require(orderBook[_orderId].expiryTime != 0, ERROR_ORDER_DOSE_NOT_EXIST); // require order exists, is there a better test?
    require(orderBook[_orderId].state == State.OPEN, ERROR_ORDER_IS_NOT_OPEN); // require order OPEN
    require(orderBook[_orderId].expiryTime > now, ERROR_ORDER_HAS_EXPIRED); // require now < expiry
    require(orderBook[_orderId].antAmmount.div(2) == _deposit, ERROR_INCORRECT_DEPOSIT_VALUE); // require deposit is correct ammount
    require(orderBook[_orderId].antAmmount < ANT.balanceOf(msg.sender), ERROR_INSUFFICIENT_FUNDS);// require msg.sender has enough DAI
    
    ANT.safeTransferFrom(msg.sender, this, _deposit);
    Order storage fillOrder = orderBook[_orderId];
    fillOrder.seller = msg.sender;
    fillOrder.antDeposit = _deposit;

    orders[msg.sender][nextOrderId] = fillOrder;
    emit FillBuyOrder(_orderId, msg.sender);
  }

  /*
  *
  */
  function fillSellOrder(uint _orderId, uint _deposit) external payable{
    require(orderBook[_orderId].expiryTime != 0, ERROR_ORDER_DOSE_NOT_EXIST); // require order exists, is there a better test?
    require(orderBook[_orderId].state == State.OPEN, ERROR_ORDER_IS_NOT_OPEN); // require order OPEN
    require(orderBook[_orderId].expiryTime > now, ERROR_ORDER_HAS_EXPIRED); // require now < expiry
    require(orderBook[_orderId].daiAmmount.div(2) == _deposit, ERROR_INCORRECT_DEPOSIT_VALUE); // require deposit is correct ammount
    require(orderBook[_orderId].daiAmmount < DAI.balanceOf(msg.sender), ERROR_INSUFFICIENT_FUNDS);// require msg.sender has enough DAI
    
    DAI.safeTransferFrom(msg.sender, this, _deposit);
    Order storage fillOrder = orderBook[_orderId];
    fillOrder.seller = msg.sender;
    fillOrder.antDeposit = _deposit;

    orders[msg.sender][nextOrderId] = fillOrder;
    emit FillSellOrder(_orderId, msg.sender);
  }

  /*
  *
  */
  function transferContract(uint _id, address _to)external {
    require(orderBook[_id].expiryTime != 0, ERROR_ORDER_DOSE_NOT_EXIST); // require order exists, is there a better test?
    require(orderBook[_id].buyer == msg.sender || orderBook[_id].buyer == msg.sender, ERROR_NOT_OWNER_OF_CONTRACT);
    
    // remove key from orders of message sender
    delete orders[msg.sender][_id];

    // change key from msg.sender to _to
    if(orderBook[_id].buyer == msg.sender){
      orderBook[_id].buyer == _to;
    }
    if(orderBook[_id].seller == msg.sender){
      orderBook[_id].seller == _to;
    }
    orders[_to][_id] = orderBook[_id];
  }

  /*
  *
  */
  function cancelOrder(uint _id) external{
      require(orders[msg.sender][_id].expiryTime != 0, ERROR_ORDER_DOSE_NOT_EXIST);
      
      // call state transition function
  }

  /*
  *
  */
  function completeOrder(uint _orderId, uint _deposit) external payable{
    require(orderBook[_orderId].buyer == msg.sender || orderBook[_orderId].buyer == msg.sender, ERROR_NOT_OWNER_OF_CONTRACT);
    require(orderBook[_orderId].expiryTime != 0, ERROR_ORDER_DOSE_NOT_EXIST); // require order exists, is there a better test?
    require(orderBook[_orderId].expiryTime > now, ERROR_PAYMENT_WINDOW_NOT_REACHED); // require order exists, is there a better test?
    require(orderBook[_orderId].expiryTime < orderBook[_orderId].closeTime, ERROR_ORDER_CLOSED); // require order exists, is there a better test?

    
    if(orderBook[_orderId].buyer == msg.sender){
        require(orderBook[_orderId].daiDeposit == _deposit, ERROR_INCORRECT_DEPOSIT_VALUE); // require deposit is correct ammount
        DAI.safeTransferFrom(msg.sender, this, _deposit);
        
        // call state transition function
    }
    
    if(orderBook[_orderId].seller == msg.sender){
        require(orderBook[_orderId].antDeposit == _deposit, ERROR_INCORRECT_DEPOSIT_VALUE); // require deposit is correct ammount
        DAI.safeTransferFrom(msg.sender, this, _deposit);
        
        // call state transition function
    }
  }

  /*
  *
  */
  function claimTokens() external payable{}

  /*
  *
  */
  function claimDeposit() external payable{}


  /*
  *
  */
  function _transitionState() internal{}

}
