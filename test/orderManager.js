var OrderBookManager = artifacts.require("./OrderBookManager.sol");
var OrderBookFactory = artifacts.require("./OrderBookFactory.sol");
var ETHOrderBook = artifacts.require("./ETHOrderBook.sol");


contract('OrderBookFactory', function(accounts) {
  var owners = [accounts[0], accounts[1], accounts[2]];
  var buyer = accounts[3];
  var seller = accounts[4];
  var orderBookManager, orderBookFactory, ethOrderBook;
  var feePercent = 0.01;
  var amount = 1;

  it("creates OrderBookFactory and transfers ownership to OrderBookManager", async function() {
    orderBookManager = await OrderBookManager.new(owners, 2, 10);
    orderBookFactory = await OrderBookFactory.new();
    await orderBookFactory.transferOwnership(orderBookManager.address);
    assert.equal(await orderBookFactory.owner(), orderBookManager.address);
  });

  it("creates a ETHOrderBook that is owned by the OrderBookManager", async function() {
    let block = await web3.eth.blocknumber;
    let tx = await orderBookFactory.createETHOrderBook({from: seller});
    var orderBookCreatedEvent = orderBookFactory.ETHOrderBookCreated({seller: seller},{fromBlock: block, toBlock: tx.receipt.blockNumber});
    orderBookCreatedEvent.watch(async function(error, result) {
      if(error) {
        console.log(error);
      }
      assert.equal(result.args.seller, seller);
      ethOrderBook = await ETHOrderBook.at(result.args.orderAddress);
      assert.equal(await ethOrderBook.owner(), orderBookManager.address);
      orderBookCreatedEvent.stopWatching();
    });
  });

});
