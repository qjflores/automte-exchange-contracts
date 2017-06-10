var ETHOrderBook = artifacts.require("./ETHOrderBook.sol");
var OrderBookManager = artifacts.require("./OrderBookManager.sol");
var OrderBookFactory = artifacts.require("./OrderBookFactory.sol");

const SolidityCoder = require("web3/lib/solidity/coder.js");

const assertInvalidOpcode = require('./helpers/assertInvalidOpcode');

const ether = function(amount) {
  return web3.toWei(amount, 'ether');
}


contract('ETHOrderBook', function(accounts) {
  var owner = accounts[0];
  var seller = accounts[1];
  var buyer = accounts[2];
  var min = ether(0.2);
  var max = ether(5);
  var country = "IN";

  var owners = [accounts[0], accounts[1], accounts[2]];
  var orderBookManager, orderBookFactory, ethOrderBook;
  var amount = 1;

  const feePercent = 0.01;

  it("creates ETHOrderBook with availableBalance of 0", async function() {
    ethOrderBook = await ETHOrderBook.new(seller, country, 1, min, max, {from: owner});
    assert.equal(await ethOrderBook.availableBalance(), 0);
  });

  it("sending ETH updates available balance", async function() {
    let value = ether(1);
    web3.eth.sendTransaction({from: seller, to: ethOrderBook.address, value: value}, async function(err, tx) {
      console.log(tx);
      web3.currentProvider.sendAsync({
        method: "eth_getTransactionReceipt",
        params: [tx],
        jsonrpc: "2.0",
        id: new Date().getTime()
      }, function (error, result) {
        console.log(result);
        if(error) console.error(error);
        console.log(ethOrderBook.address);
        console.log(result.result.logs[0].address);
        console.log(result.result.logs[0].data);
        var data = SolidityCoder.decodeParams(["uint"], result.result.logs[0].data.replace("0x", ""));
        console.log(web3.fromWei(data, 'ether'));
      });
      assert.equal(await ethOrderBook.availableBalance(), value);
    })
  })

  it("adding order from seller updates availableBalance", async function() {
    let availableBalance = web3.fromWei(await ethOrderBook.availableBalance(), 'ether');
    let contractBalance = await web3.eth.getBalance(ethOrderBook.address);
    ethOrderBook.addOrder("-1234", buyer, ether(0.5), 11015, "USD", {from: seller})
    .then(async function(txHash) {
      console.log(ethOrderBook.address);
      console.log(txHash.logs[0].address);
      console.log(txHash.logs[0].args);
      assert.equal(await ethOrderBook.availableBalance(), ether(availableBalance - (0.5+(0.5*feePercent))));
      //actual balance shouldn't change
      assert( (await web3.eth.getBalance(ethOrderBook.address)).equals(contractBalance) );
    });
  })

  it("creates OrderBookFactory and transfers ownership to OrderBookManager", async function() {
    orderBookManager = await OrderBookManager.new(owners, 2, 10);
    orderBookFactory = await OrderBookFactory.new();
    await orderBookFactory.transferOwnership(orderBookManager.address);
    assert.equal(await orderBookFactory.owner(), orderBookManager.address);
  });

  it("creates a ETHOrderBook that is owned by the OrderBookManager", async function() {
    let block = await web3.eth.blocknumber;
    orderBookFactory.createETHOrderBook(country, {from: seller})
    .then(function(txHash) {
      console.log(orderBookFactory.address);
      console.log(txHash.logs[0].address);
      console.log(txHash.logs[0].args);
    });
  });

});
