var HDWalletProvider = require("truffle-hdwallet-provider");
var fs = require("fs");
var path = require("path")
require('babel-register');
require('babel-polyfill');

var mnemonic = fs.readFileSync(path.join("./secrets/", "deploy_mnemonic.key"), {encoding: "utf8"}).trim();

module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*" // Match any network id
    },
    kovan:{
        provider: new HDWalletProvider(mnemonic, "https://kovan.infura.io/0xf4d8083560e1bde04c269132d2211d9b4c62305b"),
        network_id:42
    }
  }
};
