const exchange = artifacts.require("AragonFuturesExchange");
const end = 180; // seconds from now
const close = 180; // seconds from end

module.exports = function(deployer) {
  deployer.deploy(exchange, end, close); 
};
