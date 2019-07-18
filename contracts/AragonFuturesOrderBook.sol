pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";
import "../node_modules/zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "../node_modules/zeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";

contract AragonFuturesOrderBook {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  string private constant ERROR_ORDER_DOSE_NOT_EXIST = "ORDER_DOSE_NOT_EXIST";
  string private constant ERROR_INSUFFICIENT_FUNDS = "INSUFFICIENT_FUNDS";

  enum State {OPEN, FILLED, CLOSED, CANCELED}
  struct Order {
    uint id;
    State state;
    address buyer;
    address seller;
    uint antAmmount;
    uint daiAmmount;
  }

  ERC20 public ANT;
  ERC20 public DAI;

  Order[] public buyOrders;                         // used to search all buy orders
  Order[] public sellOrders;                        // used to search all sell orders
  mapping (address => Order[]) public userOrders;   // used to search for all orders of particular address
  mapping (uint => Order) public globalOrders;      // used to search by orderId

  uint private nextBuyOrderId;
  uint private nextSellOrderId;

  uint public startTime;  // the time when trading starts
  uint public endTime;    // the time when trading stops
  uint public closeTime;  // the time buyers and sellers must fulfill their obligation by


  event CreateBuyOrder(uint id, address maker, uint buyAmmount, uint sellAmmount);
  event CreateSellOrder(uint id, address maker, uint buyAmmount, uint sellAmmount);
  event FillBuyOrder(uint id, address taker);
  event FillSellOrder(uint id, address taker);

  constructor () public {
	ANT = ERC20(0x0D5263B7969144a852D58505602f630f9b20239D); // rinkeby
	DAI = ERC20(0x0527E400502d0CB4f214dd0D2F2a323fc88Ff924); // rinkeby
    startTime = 3600;
    endTime = 3600;
    closeTime = endTime + startTime;
    nextBuyOrderId = 0;
    nextSellOrderId = 0;
  }

  /*
  *  user can create a buy order. he specifies how much ANT he wants to buy and the rate in DAI.
  *  50% of this deposited as collatoral. the order is added to the global buyOrders list,
  *  and a mapping of the sellers address to uint, which represents all the orders this indervidual has in the exchange
  */
  function createBuyOrder(uint _buyAmmount, uint _rate) external payable hasEnoughDAI(_buyAmmount.mul(_rate).div(2)) {
    // requires

    uint deposit = _buyAmmount.mul(_rate).div(2);
    // DAI.safeTransferFrom(msg.sender, address(this), deposit); <-- this is causing tx to consume all the gas
    Order memory newOrder = Order({id: 0, state: State.OPEN, buyer: 0x0000000000000000000000000000000000000000, seller: 0x0000000000000000000000000000000000000000, antAmmount: 0, daiAmmount: 0});
    newOrder.id = nextBuyOrderId;
    newOrder.state = State.OPEN;
    newOrder.buyer = msg.sender;
    newOrder.antAmmount = _buyAmmount;
    newOrder.daiAmmount = _buyAmmount.mul(_rate);

    buyOrders.push(newOrder);
    userOrders[msg.sender].push(newOrder);
    globalOrders[nextBuyOrderId] = newOrder;

    emit CreateBuyOrder(nextBuyOrderId, msg.sender, _buyAmmount, _buyAmmount.mul(_rate));
    nextBuyOrderId++;
  }


  /*
  *  user can create a sell order. he specifies how much ANT he wants to buy and the rate in DAI.
  *  50% of this deposited as collatoral. the order is added to the global buyOrders list,
  *  and a mapping of the sellers address to uint, which represents all the orders this indervidual has in the exchange
  */
  function createSellOrder(uint _sellAmmount, uint _rate) external payable hasEnoughANT(_sellAmmount.div(2)) {
    // requires

    uint deposit = _sellAmmount.div(2);
    // ANT.safeTransferFrom(msg.sender, address(this), deposit); <-- this is causing tx to consume all the gas

    Order memory newOrder = Order({id: 0, state: State.OPEN, buyer: 0x0000000000000000000000000000000000000000, seller: 0x0000000000000000000000000000000000000000, antAmmount: 0, daiAmmount: 0});
    newOrder.id = nextSellOrderId;
    newOrder.state = State.OPEN;
    newOrder.seller = msg.sender;
    newOrder.antAmmount = _sellAmmount;
    newOrder.daiAmmount = _sellAmmount.mul(_rate);

    sellOrders.push(newOrder);
    userOrders[msg.sender].push(newOrder);
    globalOrders[nextSellOrderId];

    emit CreateSellOrder(nextSellOrderId, msg.sender, _sellAmmount.mul(_rate), _sellAmmount);
    nextSellOrderId++;
  }

  /*
  *
  */
  function fillBuyOrder(uint _orderId) external payable hasEnoughANT(globalOrders[_orderId].antAmmount.div(2)){
    // requires

    uint deposit = globalOrders[_orderId].antAmmount.div(2);
    // ANT.safeTransferFrom(msg.sender, address(this), deposit); <-- this is causing tx to consume all the gas

    globalOrders[_orderId].seller = msg.sender; // this should update the order in buyOrders and userOrders too
    emit FillBuyOrder(_orderId, msg.sender);
  }

  /*
  *
  */
  function fillSellOrder(uint _orderId, uint _deposit) external payable{}

  /*
  *
  */
  function transferOrder(uint _id, address _to)external {}

  /*
  *
  */
  function cancelOrder(uint _id) external{}

  /*
  *
  */
  function completeOrder(uint _orderId, uint _deposit) external payable{}

  /*
  *
  */
  function withdrawPurchase() external payable{}

  /*
  *
  */
  function withdrawDeposit() external payable{}

  /*
  *
  */
  function _transitionState() internal{}

  modifier hasEnoughDAI(uint _ammount) {
    //require(DAI.balanceOf(msg.sender) > _ammount, ERROR_INSUFFICIENT_FUNDS);
    _;
  }

  modifier hasEnoughANT(uint _ammount) {
    //require(ANT.balanceOf(msg.sender) > _ammount, ERROR_INSUFFICIENT_FUNDS);
    _;
  }



}
