
 const HDWalletProvider = require('truffle-hdwallet-provider');
 const infuraKey = "48e8faecc6134c88b958fb3754b2f221";

 const fs = require('fs');
 const mnemonic = fs.readFileSync(".secret").toString().trim();

module.exports = {

  plugins: ["truffle-security"],


  networks: {
     rinkeby: {
       provider: () => new HDWalletProvider(mnemonic, `https://rinkeby.infura.io/v3/4a8d55c7173e40fe9d55196a6c799864`),
       network_id: 4,       // Ropsten's id
       gas: 4500000,        // Ropsten has a lower block limit than mainnet 4500000
       confirmations: 0,    // # of confs to wait between deployments. (default: 0)
       timeoutBlocks: 50,  // # of blocks before a deployment times out  (minimum/default: 50)
       skipDryRun: true     // Skip dry run before migrations? (default: false for public nets )
     },
     development: {
      host: "127.0.0.1",     // Localhost (default: none)
      port: 7545,            // Standard Ethereum port (default: none)
      network_id: "*",       // Any network (default: none)
     },


  },

  mocha: {
    // timeout: 100000
  },

  compilers: {
    solc: {
       version: "0.4.24",    // Fetch exact version from solc-bin (default: truffle's version)
      // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
      // settings: {          // See the solidity docs for advice about optimization and evmVersion
      //  optimizer: {
      //    enabled: false,
      //    runs: 200
      //  },
      //  evmVersion: "byzantium"
      // }
    }
  }
}
