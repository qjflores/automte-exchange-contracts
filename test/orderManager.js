var OrderBookManager = artifacts.require("./OrderBookManager.sol");
var OrderBookFactory = artifacts.require("./OrderBookFactory.sol");
var ETHOrderBook = artifacts.require("./ETHOrderBook.sol");
var Router = artifacts.require("./Router.sol");


contract('OrderBookFactory', function(accounts) {
  var owners = [accounts[0], accounts[1], accounts[2]];
  var buyer = accounts[3];
  var seller = accounts[4];
  var orderBookManager, router, orderBookFactory, ethOrderBook;
  var feePercent = 0.01;
  var amount = 1;
  var country = "IN";

  it("creates a Router which sends all incoming Ether to OrderBookManager", async function() {
    router = await Router.new();
    orderBookManager = await OrderBookManager.new(owners, 3, 0, router.address);
    await router.transferOwnership(orderBookManager.address);

    let managerBalance = await web3.eth.getBalance(orderBookManager.address);
    let routerBalance = await web3.eth.getBalance(router.address);

    let value = web3.toWei(0.01, 'ether');
    await web3.eth.sendTransaction({from: accounts[0], to: router.address, value: value});

    assert( (await web3.eth.getBalance(orderBookManager.address)).equals(managerBalance.plus(value)) );

  })

  it("creates OrderBookFactory and transfers ownership to Router", async function() {
    orderBookFactory = await OrderBookFactory.new();
    await orderBookFactory.transferOwnership(router.address);
    assert.equal(await orderBookFactory.owner(), router.address);
  });

  it("creates a ETHOrderBook that is owned by the Router", async function() {
    let block = await web3.eth.blocknumber;
    let tx = await orderBookFactory.createETHOrderBook(country, {from: seller});
    var orderBookCreatedEvent = orderBookFactory.ETHOrderBookCreated({seller: seller},{fromBlock: block, toBlock: tx.receipt.blockNumber});
    orderBookCreatedEvent.watch(async function(error, result) {
      if(error) {
        console.log(error);
      }
      assert.equal(result.args.seller, seller);
      ethOrderBook = await ETHOrderBook.at(result.args.orderAddress);
      assert.equal(await ethOrderBook.owner(), router.address);
      orderBookCreatedEvent.stopWatching();
    });
  });

  it("takes 3 votes for OrderBookManager to changeOwnership of Router", async function() {
    let newOwner = accounts[5];
    await orderBookManager.changeRouterOwner(newOwner, {from: owners[0]});
    assert.equal(await router.owner(), orderBookManager.address);
    await orderBookManager.changeRouterOwner(newOwner, {from: owners[1]});
    assert.equal(await router.owner(), orderBookManager.address);
    await orderBookManager.changeRouterOwner(newOwner, {from: owners[2]});
    assert.equal(await router.owner(), newOwner);
  })

});
