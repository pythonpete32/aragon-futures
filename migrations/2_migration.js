const OrderBook = artifacts.require("AragonFuturesOrderBook");

module.exports = function(deployer) {
  deployer.deploy(OrderBook, ); //{gas: 9000000}
};
