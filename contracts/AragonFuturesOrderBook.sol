pragma solidity ^0.4.24 - 0.7.0;
pragma experimental ABIEncoderV2;

import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";
import "../node_modules/zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "../node_modules/zeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";

contract AragonFuturesOrderBook {
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
  uint public endTime;    // the time when trading stops
  uint public closeTime;  // the time buyers and sellers must fulfill their obligation by


  event CreateBuyOrder(uint id, address maker, uint buyAmmount, uint sellAmmount);
  event CreateSellOrder(uint id, address maker, uint buyAmmount, uint sellAmmount);
  event FillBuyOrder(uint id, address taker);
  event FillSellOrder(uint id, address taker);
  event TransferOrder(uint id, address sender, address reciever);

  constructor () public {
	ANT = ERC20(0x0D5263B7969144a852D58505602f630f9b20239D); // rinkeby
	DAI = ERC20(0x0527E400502d0CB4f214dd0D2F2a323fc88Ff924); // rinkeby
    startTime = 3600;
    endTime = 3600;
    closeTime = endTime + startTime;
    nextOrderId = 0;

  }

  /*
  *  user can create a buy order. he specifies how much ANT he wants to buy and the rate in DAI.
  *  50% of this deposited as collatoral. the order is added to the global buyOrders list.
  *  
  */
  function createBuyOrder(uint _buyAmmount, uint _rate) external payable hasEnoughDAI(_buyAmmount.mul(_rate).div(2)) {
    require(now < endTime, ERROR_TRADING_HAS_STOPPED);

    uint deposit = _buyAmmount.mul(_rate).div(2);
    DAI.transferFrom(msg.sender, address(this), deposit);

    Order memory newOrder = Order({
        id:nextOrderId, 
        state: State.OPEN, 
        buyer: msg.sender, 
        seller: 0x0000000000000000000000000000000000000000, 
        antAmmount: _buyAmmount, 
        daiAmmount: _buyAmmount.mul(_rate),
        buyerPaid: false,
        sellerPaid: false
    });

    globalOrders[nextOrderId] = newOrder;
    emit CreateBuyOrder(nextOrderId, msg.sender, _buyAmmount, _buyAmmount.mul(_rate));
    nextOrderId++;
  }


  /*
  *  user can create a sell order. he specifies how much ANT he wants to buy and the rate in DAI.
  *  50% of this deposited as collatoral. the order is added to the global buyOrders list.
  *  
  */
  function createSellOrder(uint _sellAmmount, uint _rate) external payable hasEnoughANT(_sellAmmount.div(2)) {
    require(now < endTime, ERROR_TRADING_HAS_STOPPED);

    uint deposit = _sellAmmount.div(2);
    ANT.transferFrom(msg.sender, address(this), deposit);
    
    Order memory newOrder = Order({
        id: nextOrderId, 
        state: State.OPEN, 
        buyer: 0x0000000000000000000000000000000000000000, 
        seller: msg.sender, 
        antAmmount: _sellAmmount, 
        daiAmmount: _sellAmmount.mul(_rate),
        buyerPaid: false,
        sellerPaid: false
    });

    globalOrders[nextOrderId] = newOrder;
    emit CreateSellOrder(nextOrderId, msg.sender, _sellAmmount.mul(_rate), _sellAmmount);
    nextOrderId++;
  }

  /*
  *
  */
  function fillBuyOrder
    (uint _orderId) 
    external 
    payable
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
  *
  */
  function fillSellOrder
    (uint _orderId)
    external 
    payable
    timedTransition(_orderId)
    atState(_orderId, State.OPEN)
    transitionState(_orderId)
    hasEnoughANT(globalOrders[_orderId].daiAmmount.div(2))
  {
    uint deposit = globalOrders[_orderId].daiAmmount.div(2);
    DAI.transferFrom(msg.sender, address(this), deposit);

    globalOrders[_orderId].seller = msg.sender; 
    emit FillSellOrder(_orderId, msg.sender);
  }
  
  
  /*
  *
  */
  function transferOrder(
    uint _orderId,
    address _to) 
    external 
    timedTransition(_orderId) 
    atState(_orderId, State.FILLED)
    {
      if (globalOrders[_orderId].buyer == msg.sender){
        globalOrders[_orderId].buyer = _to;
        emit TransferOrder(_orderId, msg.sender, _to);
      }
    
      if (globalOrders[_orderId].seller == msg.sender){
        globalOrders[_orderId].seller = _to;
        emit TransferOrder(_orderId, msg.sender, _to);
      }
  }

  /*
  *
  */
  function cancelOrder(uint _orderId) 
    external 
    timedTransition(_orderId) 
    atState(_orderId, State.OPEN) 
    {
        require(
            globalOrders[_orderId].buyer == msg.sender 
            || 
            globalOrders[_orderId].buyer == msg.sender, 
            ERROR_YOU_DO_NOT_OWN_THE_ORDER
        );
            
        globalOrders[_orderId].state = State.CANCELED;
  }

  /*
  *
  */
  function settleOrder
    (uint _orderId) 
    external 
    payable 
    timedTransition(_orderId) 
    atState(_orderId, State.SETTLEMENT)
    {
        require(
            globalOrders[_orderId].buyer == msg.sender 
            || 
            globalOrders[_orderId].buyer == msg.sender, 
            ERROR_YOU_DO_NOT_OWN_THE_ORDER
        );
        
        if (globalOrders[_orderId].buyer == msg.sender){
            uint deposit = globalOrders[_orderId].daiAmmount.div(2);
            require(DAI.balanceOf(msg.sender) > deposit, ERROR_INSUFFICIENT_FUNDS);
            DAI.transferFrom(msg.sender, address(this), deposit);
            globalOrders[_orderId].buyerPaid = true;
            
      }
    
      if (globalOrders[_orderId].seller == msg.sender){
            uint deposit2 = globalOrders[_orderId].antAmmount.div(2);
            require(ANT.balanceOf(msg.sender) > deposit2, ERROR_INSUFFICIENT_FUNDS);
            ANT.transferFrom(msg.sender, address(this), deposit2);
            globalOrders[_orderId].sellerPaid = true;
      }
    }

  /*
  * this function looks horrendous, i will have to refactor this at a later stage, but for now as long as it works
  * ill write the unit tests and refactor later
  *
  function withdrawPurchase
      (uint _orderId) 
      external 
      payable
      timedTransition(_orderId)
      atState(_orderId, State.CLOSED)
      {
        require(
            globalOrders[_orderId].buyer == msg.sender 
            || 
            globalOrders[_orderId].buyer == msg.sender, 
            ERROR_YOU_DO_NOT_OWN_THE_ORDER
        );
        
          // there are four possible senarios there
          // 1. both parites paid and can withdraw their respecxtive purchaces
          // 2. buyer defaults and the seller collects both deposits
          // 3. seller defaults and buyer collects both deposits
          // 4. both default and collect their deposit back
          if(msg.sender == globalOrders[_orderId].buyer){
              if(globalOrders[_orderId].buyerPaid == true && globalOrders[_orderId].sellerPaid == true){
                  ANT.transfer(msg.sender, globalOrders[_orderId].antAmmount); 
              }
              if(globalOrders[_orderId].buyerPaid == true && globalOrders[_orderId].sellerPaid == false){
                  ANT.transfer(msg.sender, globalOrders[_orderId].antAmmount.div(2)); 
                  DAI.transfer(msg.sender, globalOrders[_orderId].daiAmmount.div(2));
              }
              if(globalOrders[_orderId].buyerPaid == false && globalOrders[_orderId].sellerPaid == true){
                  revert(ERROR_YOU_DEFAULTED);
              }
              if(globalOrders[_orderId].buyerPaid == false && globalOrders[_orderId].sellerPaid == false){
                  DAI.transfer(msg.sender, globalOrders[_orderId].daiAmmount.div(2));              
              }
          } 
          
          if(msg.sender == globalOrders[_orderId].seller){
              if(globalOrders[_orderId].buyerPaid == true && globalOrders[_orderId].sellerPaid == true){
                  DAI.transfer(msg.sender, globalOrders[_orderId].daiAmmount);              
              }
              if(globalOrders[_orderId].buyerPaid == true && globalOrders[_orderId].sellerPaid == false){
                  ANT.transfer(msg.sender, globalOrders[_orderId].antAmmount.div(2)); 
                  DAI.transfer(msg.sender, globalOrders[_orderId].daiAmmount.div(2));              
              }
              if(globalOrders[_orderId].buyerPaid == false && globalOrders[_orderId].sellerPaid == true){
                  revert(ERROR_YOU_DEFAULTED);              
              }
              if(globalOrders[_orderId].buyerPaid == false && globalOrders[_orderId].sellerPaid == false){
                  ANT.transfer(msg.sender, globalOrders[_orderId].antAmmount.div(2));               
              }
          }
      }
      */

  /*
  *
  */
  function withdrawDeposit(uint _orderId) external payable atState(_orderId, State.CANCELED){
        require(
            globalOrders[_orderId].buyer == msg.sender 
            || 
            globalOrders[_orderId].buyer == msg.sender, 
            ERROR_YOU_DO_NOT_OWN_THE_ORDER
        );
        
        if (msg.sender == globalOrders[_orderId].buyer){
            DAI.transfer(msg.sender, globalOrders[_orderId].daiAmmount.div(2));
        }
        if (msg.sender == globalOrders[_orderId].seller){
            ANT.transfer(msg.sender, globalOrders[_orderId].daiAmmount.div(2));
        }
  }

  /*
  *
  */


  modifier hasEnoughDAI(uint _ammount) {
    require(DAI.balanceOf(msg.sender) > _ammount, ERROR_INSUFFICIENT_FUNDS);
    _;
  }

  modifier hasEnoughANT(uint _ammount) {
    require(ANT.balanceOf(msg.sender) > _ammount, ERROR_INSUFFICIENT_FUNDS);
    _;
  }
  
  modifier atState(uint _orderId, State _state) {
    require(
        globalOrders[_orderId].state == _state, 
        ERROR_CANNOT_CALL_THIS_FUNCTION_IN_THIS_STATE
    );
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
  
  modifier transitionState(uint _orderId){
    State currentState = globalOrders[_orderId].state;
    globalOrders[_orderId].state = State(uint(currentState) + 1);
    _;
  }



}
