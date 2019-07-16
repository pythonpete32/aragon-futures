pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;
/*
  In this implimentation, futures contracts are not fungible.
  - order creator selects expiry time
  - Contract closes one hour after expiry
*/


import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";
import "../node_modules/zeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract AragonFuturesOrderBook {
  using SafeMath for uint256;

  string private constant ERROR_ORDER_DOSE_NOT_EXIST = "ORDER_DOSE_NOT_EXIST";
  string private constant ERROR_NOT_OWNER_OF_CONTRACT = "NOT_OWNER_OF_CONTRACT"; 
  string private constant ERROR_ORDER_IS_NOT_OPEN = "ORDER_IS_NOT_OPEN";
  string private constant ERROR_ORDER_HAS_EXPIRED = "ORDER_HAS_EXPIRED";
  string private constant ERROR_INSUFFICIENT_FUNDS = "INSUFFICIENT_FUNDS";


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
	
  address owner;
	ERC20 ANT;
	ERC20 DAI;
  enum State {OPEN, FILLED, EXPIRED}
  mapping (uint => Order) public orderBook;
  mapping (address => mapping (uint => Order)) public orders;
  uint nextOrderId;

  event CreateBuyOrder(uint id, address maker, uint buyAmmount, uint sellAmmount, uint expiry);
  event CreateSellOrder(uint id, address maker, uint buyAmmount, uint sellAmmount, uint expiry);
  event FillBuyOrder(uint id, address taker);
  event FillSellOrder(uint id, address taker);

  constructor () public {
    owner = msg.sender;
    nextOrderId = 0;
		ANT = ERC20(0x0d5263b7969144a852d58505602f630f9b20239d); // rinkeby
		DAI = ERC20(0x0527e400502d0cb4f214dd0d2f2a323fc88ff924); // rinkeby
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
    // require msg.sender has enough DAI
    // require deposit is correct ammount
    Order storage newOrder = orderBook[nextOrderId];
    orderBook[nextOrderId].id = nextOrderId;
    orderBook[nextOrderId].state = State.OPEN;
    orderBook[nextOrderId].buyer = msg.sender;
    orderBook[nextOrderId].antAmmount = _buyAmmount;
    orderBook[nextOrderId].daiAmmount = _sellAmmount;
    orderBook[nextOrderId].daiDeposit = _deposit;
    orderBook[nextOrderId].expiryTime = now + _expiry;
    orderBook[nextOrderId].closeTime = orderBook[nextOrderId].expiryTime + 3600; // 1 hour

    this._deposit(_deposit);
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
    // require msg.sender has enough ANT
    // require deposit is correct ammount
    Order storage newOrder = orderBook[nextOrderId];
    orderBook[nextOrderId].id = nextOrderId;
    orderBook[nextOrderId].state = State.OPEN;
    orderBook[nextOrderId].seller = msg.sender;
    orderBook[nextOrderId].antAmmount = _buyAmmount;
    orderBook[nextOrderId].daiAmmount = _sellAmmount;
    orderBook[nextOrderId].antDeposit = _deposit;
    orderBook[nextOrderId].expiryTime = now + _expiry;
    orderBook[nextOrderId].closeTime = orderBook[nextOrderId].expiryTime + 3600; // 1 hour

    this._deposit(_deposit);
    orders[msg.sender][nextOrderId] = newOrder;
    emit CreateSellOrder(nextOrderId, msg.sender, _buyAmmount, _sellAmmount, _expiry);
    nextOrderId ++;
  }

  /*
  *
  */
  function fillBuyOrder(uint _orderId, uint _deposit) external payable{
    // require order exists
    // require order OPEN
    // require now < expiry
    // require deposit is correct ammount
    // require msg.sender has enough ANT
    Order storage fillOrder = orderBook[_orderId];
    fillOrder.seller = msg.sender;
    fillOrder.antDeposit = _deposit;

    this._deposit(_deposit);
    orders[msg.sender][nextOrderId] = fillOrder;
    emit FillBuyOrder(_orderId, msg.sender);
  }

  /*
  *
  */
  function fillSellOrder(uint _orderId, uint _deposit) external payable{
    // require order exists
    // require order OPEN
    // require now < expiry
    // require deposit is correct ammount
    // require msg.sender has enough ANT
    Order storage fillOrder = orderBook[_orderId];
    fillOrder.buyer = msg.sender;
    fillOrder.daiDeposit = _deposit;

    this._deposit(_deposit);
    orders[msg.sender][nextOrderId] = fillOrder;
    emit FillSellOrder(_orderId, msg.sender);
  }

  /*
  *
  */
  function transferContract(uint _id, address _to)external {
    //how do i test for a null entry
    require(orderBook[_id].buyer == msg.sender || orderBook[_id].buyer == msg.sender, ERROR_NOT_OWNER_OF_CONTRACT) ;
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
  function cancelOrder() external{}

  /*
  *
  */
  function completeOrder() external payable{}

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
  function getOrders(address add) external view returns(Order[]){

  }

  /*
  *
  */
  function _transitionState() internal{}

  /*
  *
  */
  function _deposit(uint _ammount){}
}
