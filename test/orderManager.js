var OrderBookManager = artifacts.require("./OrderBookManager.sol");
var OrderBookFactory = artifacts.require("./OrderBookFactory.sol");
var ETHOrderBook = artifacts.require("./ETHOrderBook.sol");
var Router = artifacts.require("./Router.sol");
var MultiSigWallet = artifacts.require("./MultiSigWallet.sol");


contract('OrderBookFactory', function(accounts) {
  var owners = [accounts[0], accounts[1], accounts[2]];
  var buyer = accounts[3];
  var seller = accounts[4];
  var orderBookManager, router, orderBookFactory, ethOrderBook, multisig;
  var feePercent = 0.01;
  var amount = 1;
  var country = "IN";

  it("creates a Router which sends all incoming Ether to OrderBookManager", async function() {
    router = await Router.new();
    multisig = await MultiSigWallet.new(owners, 3);
    await router.transferOwnership(multisig.address);

    let multisigBalance = await web3.eth.getBalance(multisig.address);
    let routerBalance = await web3.eth.getBalance(router.address);

    let value = web3.toWei(0.01, 'ether');
    await web3.eth.sendTransaction({from: accounts[0], to: router.address, value: value});

    assert( (await web3.eth.getBalance(multisig.address)).equals(multisigBalance.plus(value)) );

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
    //var myCallData = myContractInstance.myMethod.getData(param1 [, param2, ...]);
    var callData = router.contract.transferOwnership.getData(newOwner);
    await multisig.submitTransaction(router.address, 0, callData, {from: owners[0]});
    assert.equal(await router.owner(), multisig.address);
    var txConfirmedEvent = multisig.Confirmation({sender: owners[0]});

    txConfirmedEvent.watch(async function(error, result) {
        var id = result["args"]["transactionId"];
        await multisig.confirmTransaction(id, {from: owners[1]});
        assert.equal(await router.owner(), multisig.address);
        await multisig.confirmTransaction(id, {from: owners[2]});
        assert.equal(await router.owner(), newOwner);
        txConfirmedEvent.stopWatching();
    });
  })

});
