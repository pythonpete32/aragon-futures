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

  Order[] public buyOrders;
  Order[] public SellOrders;
  mapping (address => Order[]) public orders;
  uint private nextBuyOrderId;
  uint private nextSellOrderId;

  uint public startTime;  // the time when trading starts
  uint public endTime;    // the time when trading stops
  uint public closeTime;  // the time buyers and sellers must fulfill their obligation by


  event CreateBuyOrder(uint id, address maker, uint buyAmmount, uint sellAmmount);
  event CreateSellOrder(uint id, address maker, uint buyAmmount, uint sellAmmount);
  event FillBuyOrder(uint id, address taker);
  event FillSellOrder(uint id, address taker);

  constructor (uint _endTime, uint _closeTime) public {
	ANT = ERC20(0x0D5263B7969144a852D58505602f630f9b20239D); // rinkeby
	DAI = ERC20(0x0527E400502d0CB4f214dd0D2F2a323fc88Ff924); // rinkeby
    startTime = now;
    endTime = _endTime;
    closeTime = _endTime + _closeTime;
    nextBuyOrderId = 0;
    nextSellOrderId = 0;
  }

  /*
  *
  */
  function createBuyOrder(uint _buyAmmount, uint _sellRate) external payable hasEnoughDAI(_buyAmmount.div(2)) {
    // DAI.safeTransferFrom(msg.sender, address(this), _buyAmmount.div(2));
    Order storage newOrder = buyOrders[nextBuyOrderId]; // is this the reason why the transaction is running out of gas?
    //newOrder.id = nextBuyOrderId;
    //newOrder.state = State.OPEN;
    //newOrder.buyer = msg.sender;
    //newOrder.antAmmount = _buyAmmount.mul(_sellRate);
    //newOrder.daiAmmount = _buyAmmount;

    //buyOrders.push(newOrder);
    //orders[msg.sender].push(newOrder);
  }

  /*
  *
  */
  function createSellOrder(uint _buyAmmount, uint _sellAmmount) external payable{}

  /*
  *
  */
  function fillBuyOrder(uint _orderId) external payable{}

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
    require(DAI.balanceOf(msg.sender) > _ammount, ERROR_INSUFFICIENT_FUNDS);
    _;
  }

}
