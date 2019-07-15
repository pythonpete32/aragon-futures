const OrderBook = artifacts.require("AragonFuturesOrderBook");

module.exports = function(deployer) {
  deployer.deploy(OrderBook);
};
