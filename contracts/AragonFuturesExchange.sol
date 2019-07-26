pragma solidity ^0.4.24 - 0.7.0;
pragma experimental ABIEncoderV2;

import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";
import "../node_modules/zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "../node_modules/zeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";

contract AragonFuturesExchange {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  string private constant ERROR_ORDER_DOSE_NOT_EXIST = "ORDER_DOSE_NOT_EXIST";
  string private constant ERROR_INSUFFICIENT_FUNDS = "INSUFFICIENT_FUNDS";
  string private constant ERROR_CANNOT_CALL_THIS_FUNCTION_IN_THIS_STATE = "CANNOT_CALL_THIS_FUNCTION_IN_THIS_STATE";
  string private constant ERROR_TRADING_HAS_STOPPED = "TRADING_HAS_STOPPED";
  string private constant ERROR_YOU_DO_NOT_OWN_THE_ORDER = "YOU_DO_NOT_OWN_THE_ORDER";
  string private constant ERROR_YOU_DEFAULTED = "YOU_DEFAULTED";

  enum State {
    OPEN,       // order is on the order book, with deposit paid, waiting to be filled
    FILLED,     // order has filled, buyer and seller has paid deposit
    SETTLEMENT, // order is waiting for both parties to pay the remaining balance
    CLOSED,     // parties can withdraw there purchaces or deposits if both fail to pay remaning balance
    CANCELED    // open order has been withdrawn from the order book
  }

  struct Order {
    uint id;
    State state;
    address buyer;
    address seller;
    uint antAmmount;
    uint daiAmmount;
    bool buyerPaid;
    bool sellerPaid;
  }

  ERC20 public ANT;
  ERC20 public DAI;


  mapping (uint => Order) public globalOrders;      // all orders of this exchange in this time period

  uint private nextOrderId;
  uint public startTime;  // the time when trading starts
  uint public endTime;    // the time when trading stops n
  uint public closeTime;  // the time buyers and sellers must fulfill their obligation by


  event CreateBuyOrder(uint id, address maker, uint buyAmmount, uint sellAmmount);
  event CreateSellOrder(uint id, address maker, uint buyAmmount, uint sellAmmount);
  event FillBuyOrder(uint id, address taker);
  event FillSellOrder(uint id, address taker);
  event TransferOrder(uint id, address sender, address reciever);

  constructor (uint _end, uint _close) public {
	ANT = ERC20(0x0D5263B7969144a852D58505602f630f9b20239D); // rinkeby 0x0D5263B7969144a852D58505602f630f9b20239D // rpc 0x370587127bBC6B15a928cFc3916295Eb7940A9BF
	DAI = ERC20(0x0527E400502d0CB4f214dd0D2F2a323fc88Ff924); // rinkeby 0x0527E400502d0CB4f214dd0D2F2a323fc88Ff924 // rpc 0xA16Dca8E28e8054C766A9D21c967C6ee6D822964
    startTime = now;
    endTime = startTime + _end;  // <-- use args after testing
    closeTime = endTime + _close;  // <-- use args after testing
    nextOrderId = 0;

  }


  /***** external functions *****/

  /*
  * @notice returns the state of the exchange (open, settling, closed) and the time left
  */
  function stageTime() external view returns (string memory stg, string memory isFin, int tme) {
    string memory stage;
    string memory isFinished;
    int time;

    if (now < endTime){
      stage = 'open';
      time = int(endTime) - int(now);
      isFinished = 'time left:';
    }

    if (now > endTime && now < closeTime){
      stage = 'settlement period';
      time = int(closeTime) - int(now);
      isFinished = 'time left:';
    }

    if (now > closeTime){
      stage = 'closed';
      time = int(now) - int(closeTime);
      isFinished = 'time Since Closed:';
    }

    return(stage, isFinished, time);
  }


  /*
  *  @notice user can create a buy order, 50% of this deposited as collatoral.
  *  @param _buyAmmount is the ammount of ANT user wants to buys, in whole ANT units
  *  @param _rate is the ammount of DAI the buyer wants to pay for 1 ANT
  */
  function createBuyOrder(uint _buyAmmount, uint _rate) external hasEnoughDAI(_buyAmmount.mul(_rate).div(2)) {
    require(now < endTime, ERROR_TRADING_HAS_STOPPED);

    uint buyAmmount = _buyAmmount.mul(10**18);
    uint deposit = buyAmmount.mul(_rate).div(2);
    DAI.transferFrom(msg.sender, address(this), deposit);

    Order memory newOrder = Order({
      id:nextOrderId,
      state: State.OPEN,
      buyer: msg.sender,
      seller: 0x0000000000000000000000000000000000000000,
      antAmmount: buyAmmount,
      daiAmmount: buyAmmount.mul(_rate),
      buyerPaid: false,
      sellerPaid: false
    });

    globalOrders[nextOrderId] = newOrder;
    emit CreateBuyOrder(nextOrderId, msg.sender, buyAmmount, buyAmmount.mul(_rate));
    nextOrderId++;
  }

  /*
  *  @notice user can create a sell order. 50% of this deposited as collatoral.
  *  @param _sellAmount is the ammount of ANT user wants to sell
  *  @param _rate is the ammount of DAI the buyer wants to recieve for 1 ANT
  */
  function createSellOrder(uint _sellAmmount, uint _rate) external hasEnoughANT(_sellAmmount.div(2)) {
    require(now < endTime, ERROR_TRADING_HAS_STOPPED);

    uint sellAmmount = _sellAmmount.mul(10**18);
    uint deposit = sellAmmount.div(2);
    ANT.transferFrom(msg.sender, address(this), deposit);

    Order memory newOrder = Order({
      id: nextOrderId,
      state: State.OPEN,
      buyer: 0x0000000000000000000000000000000000000000,
      seller: msg.sender,
      antAmmount: sellAmmount,
      daiAmmount: sellAmmount.mul(_rate),
      buyerPaid: false,
      sellerPaid: false
    });

    globalOrders[nextOrderId] = newOrder;
    emit CreateSellOrder(nextOrderId, msg.sender, sellAmmount.mul(_rate), sellAmmount);
    nextOrderId++;
  }

  /*
  * @notice user can select a buy order from the orderbook and fill it
  * @param _orderId is the id of the order to be filled
  */
  function fillBuyOrder
    (uint _orderId)
    external
    timedTransition(_orderId)
    atState(_orderId, State.OPEN)
    transitionState(_orderId)
    hasEnoughANT(globalOrders[_orderId].antAmmount.div(2))
  {
      uint deposit = globalOrders[_orderId].antAmmount.div(2);
      ANT.transferFrom(msg.sender, address(this), deposit);

      globalOrders[_orderId].seller = msg.sender;
      emit FillBuyOrder(_orderId, msg.sender);
  }

  /*
  * @notice user can select a sell order from the orderbook and fill it
  * @param _orderId is the id of the order to be filled
  */
  function fillSellOrder
    (uint _orderId)
    external
    timedTransition(_orderId)
    atState(_orderId, State.OPEN)
    transitionState(_orderId)
    hasEnoughANT(globalOrders[_orderId].daiAmmount.div(2))
  {
    uint deposit = globalOrders[_orderId].daiAmmount.div(2);
    DAI.transferFrom(msg.sender, address(this), deposit);

    globalOrders[_orderId].buyer = msg.sender;
    emit FillSellOrder(_orderId, msg.sender);
  }


  /*
  * @notice user can transfer ownership of filled order (secondary market)
  * @param _orderId the id of the order to be transfered
  * @param _to the address to transfer to
  */
  function transferOrder(
    uint _orderId,
    address _to
  )
    external
    timedTransition(_orderId)
    atState(_orderId, State.FILLED)
  {
    Order memory order = globalOrders[_orderId];
    require(order.buyer == msg.sender || order.seller == msg.sender, ERROR_YOU_DO_NOT_OWN_THE_ORDER);
    if (order.buyer == msg.sender){
      globalOrders[_orderId].buyer = _to;
      emit TransferOrder(_orderId, msg.sender, _to);
    }

    if (order.seller == msg.sender){
      globalOrders[_orderId].seller = _to;
      emit TransferOrder(_orderId, msg.sender, _to);
    }
  }

  /*
  * @notice if the order has not been filled, user can cancel their order
  * @param _orderId the id of the order to be canceled
  */
  function cancelOrder(uint _orderId)
    external
    timedTransition(_orderId)
    atState(_orderId, State.OPEN)
  {
    Order memory order = globalOrders[_orderId];
    require(order.buyer == msg.sender || order.seller == msg.sender, ERROR_YOU_DO_NOT_OWN_THE_ORDER);

    globalOrders[_orderId].state = State.CANCELED;
  }

  /*
  * @notice user pays the outstanding balance after the expiry date
  * @param _orderId the id of the order to be settled
  */
  function settleOrder
    (uint _orderId)
    external
    timedTransition(_orderId)
    atState(_orderId, State.SETTLEMENT)
  {
    Order memory order = globalOrders[_orderId];
    require(order.buyer == msg.sender || order.buyer == msg.sender, ERROR_YOU_DO_NOT_OWN_THE_ORDER);

    if (order.buyer == msg.sender){
      uint deposit = order.daiAmmount.div(2);
      require(DAI.balanceOf(msg.sender) > deposit, ERROR_INSUFFICIENT_FUNDS);
      DAI.transferFrom(msg.sender, address(this), deposit);
      globalOrders[_orderId].buyerPaid = true;
    }

    if (order.seller == msg.sender){
      uint deposit2 = order.antAmmount.div(2);
      require(ANT.balanceOf(msg.sender) > deposit2, ERROR_INSUFFICIENT_FUNDS);
      ANT.transferFrom(msg.sender, address(this), deposit2);
      globalOrders[_orderId].sellerPaid = true;
    }
  }

  /*
  * @notice buyer can withdraw their purchase after the settlement period ends
  * @param _orderId the id of the purchace
  */
  function withdrawBuyerPurchase
    (uint _orderId)
    external
    timedTransition(_orderId)
    atState(_orderId, State.CLOSED)
  {
    Order memory order = globalOrders[_orderId];
    require(order.buyer == msg.sender, ERROR_YOU_DO_NOT_OWN_THE_ORDER);

    // there are four possible senarios here
    // 1. both parites paid and can withdraw their respecxtive purchaces
    // 2. buyer defaults and the seller collects both deposits
    // 3. seller defaults and buyer collects both deposits
    // 4. both default and collect their deposit back

    if(order.buyerPaid == true && order.sellerPaid == true){
      ANT.transfer(msg.sender, order.antAmmount);
    }

    if(order.buyerPaid == true && order.sellerPaid == false){
      ANT.transfer(msg.sender, order.antAmmount.div(2));
      DAI.transfer(msg.sender, order.daiAmmount.div(2));
    }

    if(order.buyerPaid == false && order.sellerPaid == true){
      revert(ERROR_YOU_DEFAULTED);
    }

    if(order.buyerPaid == false && order.sellerPaid == false){
      DAI.transfer(msg.sender, order.daiAmmount.div(2));
    }
  }

  /*
  * @notice seller can withdraw their purchase after the settlement period ends
  * @param _orderId the id of the purchace
  */
  function withdrawSellerPurchase
    (uint _orderId)
    external
    timedTransition(_orderId)
    atState(_orderId, State.CLOSED)
  {
    Order memory order = globalOrders[_orderId];
    require(order.seller == msg.sender, ERROR_YOU_DO_NOT_OWN_THE_ORDER);

    // there are four possible senarios here
    // 1. both parites paid and can withdraw their respecxtive purchaces
    // 2. buyer defaults and the seller collects both deposits
    // 3. seller defaults and buyer collects both deposits
    // 4. both default and collect their deposit back

    if(order.buyerPaid == true && order.sellerPaid == true){
      DAI.transfer(msg.sender, order.daiAmmount);
    }

    if(order.buyerPaid == true && order.sellerPaid == false){
      ANT.transfer(msg.sender, order.antAmmount.div(2));
      DAI.transfer(msg.sender, order.daiAmmount.div(2));
    }

    if(order.buyerPaid == false && order.sellerPaid == true){
      revert(ERROR_YOU_DEFAULTED);
    }

    if(order.buyerPaid == false && order.sellerPaid == false){
      ANT.transfer(msg.sender, order.antAmmount.div(2));
    }
  }

  /*
  * @notice the user can withdraw their deposit after canceling an order
  * @param _orderId the id of the order to clam deposit back against
  */
  function withdrawDeposit(uint _orderId) external atState(_orderId, State.CANCELED){
    Order memory order = globalOrders[_orderId];
    require(order.buyer == msg.sender || order.seller == msg.sender, ERROR_YOU_DO_NOT_OWN_THE_ORDER);

    if (msg.sender == order.buyer){
      DAI.transfer(msg.sender, order.daiAmmount.div(2));
    }

    if (msg.sender == order.seller){
      ANT.transfer(msg.sender, order.daiAmmount.div(2));
    }
  }


  /***** modifiers *****/


  modifier hasEnoughDAI(uint _ammount) {
    require(DAI.balanceOf(msg.sender) > _ammount, ERROR_INSUFFICIENT_FUNDS);
    _;
  }

  modifier hasEnoughANT(uint _ammount) {
    require(ANT.balanceOf(msg.sender) > _ammount, ERROR_INSUFFICIENT_FUNDS);
    _;
  }

  modifier atState(uint _orderId, State _state) {
    require(globalOrders[_orderId].state == _state, ERROR_CANNOT_CALL_THIS_FUNCTION_IN_THIS_STATE);
    _;
  }

  modifier transitionState(uint _orderId){
    State currentState = globalOrders[_orderId].state;
    globalOrders[_orderId].state = State(uint(currentState) + 1);
    _;
  }

  modifier timedTransition(uint _orderId){
    // there are three time dependant transitions
    // 1. OPEN transitions to CANCELED if they are not filled by endTime
    // 2. FILLED orders transitions to SETTLEMENT if now > endTime && now < closeTime
    // 3. SETTLEMENT transitions to CLOSED if now > closeTime

    if(globalOrders[_orderId].state == State.OPEN && now > endTime){
      globalOrders[_orderId].state = State.CANCELED;
      this.cancelOrder(_orderId);
    }

    if(globalOrders[_orderId].state == State.FILLED && now > endTime && now < closeTime){
      globalOrders[_orderId].state = State.SETTLEMENT;
    }

    if(globalOrders[_orderId].state == State.SETTLEMENT && now > closeTime){
      globalOrders[_orderId].state = State.CLOSED;
    }

    _;
  }
}
