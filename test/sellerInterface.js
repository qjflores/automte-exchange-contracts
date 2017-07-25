var SellerInterface = artifacts.require("./SellerInterface.sol");
var OrderDB = artifacts.require("./OrderDB.sol");
var OrderDBI = artifacts.require("./OrderDBI.sol");
var OrderBook = artifacts.require("./OrderBook.sol");
var BuggyOrderBook = artifacts.require("./BuggyOrderBook.sol");
var OrderBookI = artifacts.require("./OrderBookI.sol");
var MultiSigWallet = artifacts.require("./MultiSigWallet.sol");

const BigNumber = web3.BigNumber

const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bignumber')(BigNumber))
  .should()

const assertInvalidOpcode = require('./helpers/assertInvalidOpcode');

const ether = function(amount) {
  return web3.toWei(amount, 'ether');
}


contract('SellerInterface', function(accounts) {
  var sellerInterface, orderDb, orderBook, multisig, buggyOrderBook;
  const owner = accounts[0];
  const owners = [accounts[0], accounts[3], accounts[4]];
  const seller = accounts[1];
  const buyer = accounts[2];

  const feePercent = 100; //100 = 1%, 1 = 0.01%

  before(async function() {
    orderDb = await OrderDB.new();
    orderBook = await OrderBook.new(orderDb.address);
    buggyOrderBook = await BuggyOrderBook.new();
    // await orderDb.setOrderBook(buggyOrderBook.address);
    await orderDb.setFeePercent(feePercent);
    await orderDb.setLimits(0, ether(5));

    multisig = await MultiSigWallet.new(owners, 3);
    await orderDb.setFeeRecipient(multisig.address);
  });


  //Functionnality
  it("creates SellerInterface", async function() {
    sellerInterface = await SellerInterface.new(seller, orderDb.address, {from: seller});
  });

  it("depositing ether updates balance in db and contract balance", async function() {
    const block = await web3.eth.blocknumber;
    const value = ether(1);
    const interfaceBalanceBefore = await web3.eth.getBalance(sellerInterface.address);
    const tx = await sellerInterface.deposit({from: seller, value: value});

    const interfaceBalanceAfter = await web3.eth.getBalance(sellerInterface.address);
    interfaceBalanceAfter.should.be.bignumber.equal(interfaceBalanceBefore.plus(value));

    const balanceUpdatedEvent = orderDb.BalanceUpdated({sellerInterface: sellerInterface.address, newBalance: value}, {fromBlock: block, toBlock: tx.receipt.blockNumber});
    await balanceUpdatedEvent.get(function(error, logs) {
      const event = logs.find(e => e.event === 'BalanceUpdated')

      should.exist(event)
      event.args.sellerInterface.should.equal(sellerInterface.address)
      event.args.newBalance.should.be.bignumber.equal(value)
    })
  });

  it("withdrawing ether updates balance in db and contract balance, sends ether to seller", async function() {
    const block = await web3.eth.blocknumber;
    const value = ether(0.5);
    const sellerBalanceBefore = await web3.eth.getBalance(seller);
    const interfaceBalanceBefore = await web3.eth.getBalance(sellerInterface.address);
    const tx = await sellerInterface.withdraw(value, {from: seller});

    const interfaceBalanceAfter = await web3.eth.getBalance(sellerInterface.address);
    interfaceBalanceAfter.should.be.bignumber.equal(interfaceBalanceBefore.minus(value));

    const sellerBalanceAfter = await web3.eth.getBalance(seller);
    sellerBalanceAfter.should.be.bignumber.gt(sellerBalanceBefore);

    const balanceUpdatedEvent = orderDb.BalanceUpdated({sellerInterface: sellerInterface.address, newBalance: value}, {fromBlock: block, toBlock: tx.receipt.blockNumber});
    await balanceUpdatedEvent.get(function(error, logs) {
      const event = logs.find(e => e.event === 'BalanceUpdated')

      should.exist(event)
      event.args.sellerInterface.should.equal(sellerInterface.address)
      event.args.newBalance.should.be.bignumber.equal(value)
    })
  })

  it("can't addOrder if orderBook logic isn't set", async function() {
    const uid = "-KlXQoew7-TCFB6o9ci-";
    const amount = new BigNumber(ether(0.3));
    const fee = amount.mul(0.01);
    const price = 250;
    const currency = "USD"

    try {
      await sellerInterface.addOrder(uid, buyer, amount, price, currency, {from: seller});
    } catch(error) {
      assertInvalidOpcode(error);
    }
  })

  it("can switch orderBook logic", async function() {
    await orderDb.setOrderBook(buggyOrderBook.address);

    const block = await web3.eth.blocknumber;
    const uid = "-KlXQoew7-TCFB6o9ci-";
    const amount = await orderDb.availableBalances(sellerInterface.address);
    const price = 250;
    const currency = "USD"

    await sellerInterface.addOrder(uid, buyer, amount, price, currency, {from: seller});

    await orderDb.setOrderBook(orderBook.address);

    try {
      await sellerInterface.addOrder(uid, buyer, amount, price, currency, {from: seller});
    } catch(error) {
      assertInvalidOpcode(error);
    }
  })

  it("adding an order updates balance in db, not contract balance", async function() {
    const block = await web3.eth.blocknumber;
    const uid = "-KlXQoew7-TCFB6o9ci-";
    const amount = new BigNumber(ether(0.3));
    const fee = amount.mul(0.01);
    const price = 250;
    const currency = "USD"
    const interfaceBalanceBefore = await web3.eth.getBalance(sellerInterface.address);
    const sellerBalance = await orderDb.availableBalances(sellerInterface.address);
    const sellerBalanceAfter = sellerBalance.minus(amount.plus(fee));

    const tx = await sellerInterface.addOrder(uid, buyer, amount, price, currency, {from: seller});

    (await web3.eth.getBalance(sellerInterface.address)).should.be.bignumber.equal(interfaceBalanceBefore);

    const balanceUpdatedEvent = orderDb.BalanceUpdated({sellerInterface: sellerInterface.address}, {fromBlock: block, toBlock: tx.receipt.blockNumber});
    await balanceUpdatedEvent.get(function(error, logs) {
      const event = logs.find(e => e.event === 'BalanceUpdated')

      should.exist(event)
      event.args.sellerInterface.should.equal(sellerInterface.address)
      event.args.newBalance.should.be.bignumber.equal(sellerBalanceAfter);
    })

    const orderAddedEvent = orderBook.OrderAdded({seller: sellerInterface.address}, {fromBlock: block, toBlock: tx.receipt.blockNumber});
    await orderAddedEvent.get(function(error, logs) {
      const event = logs.find(e => e.event === 'OrderAdded')

      should.exist(event)

      event.args.uid.should.equal(uid)
      event.args.seller.should.equal(sellerInterface.address)
      event.args.buyer.should.equal(buyer)
      event.args.amount.should.be.bignumber.equal(amount)
      event.args.price.should.be.bignumber.equal(price)
      event.args.currency.should.equal(currency)
      event.args.availableBalance.should.be.bignumber.equal(sellerBalanceAfter);
    })
  })

  it("completing an order should not use ether if buyer does not receive amount", async function() {
    await orderDb.setOrderBook(buggyOrderBook.address);

    const uid = "-KlXQoew7-TCFB6o9ci-";
    const block = await web3.eth.blocknumber;
    const sellerContractBalanceBefore = await web3.eth.getBalance(sellerInterface.address);
    const buyerBalanceBefore = await web3.eth.getBalance(buyer);
    const multisigBalanceBefore = await web3.eth.getBalance(multisig.address);

    try {
      await sellerInterface.completeOrder(uid, {from: seller});
    } catch(error) {
      assertInvalidOpcode(error);
    }

    (await web3.eth.getBalance(sellerInterface.address)).should.be.bignumber.equal(sellerContractBalanceBefore);
  })

  it("completing an order sends ether to buyer and fee to feeRecipient", async function() {
    await orderDb.setOrderBook(orderBook.address);

    const uid = "-KlXQoew7-TCFB6o9ci-";
    const block = await web3.eth.blocknumber;
    const buyerBalanceBefore = await web3.eth.getBalance(buyer);
    const multisigBalanceBefore = await web3.eth.getBalance(multisig.address);

    const tx = await sellerInterface.completeOrder(uid, {from: seller});

    const multisigBalanceAfter = await web3.eth.getBalance(multisig.address);
    const buyerBalanceAfter = await web3.eth.getBalance(buyer);

    const orderCompletedEvent = orderBook.OrderCompleted({seller: sellerInterface.address}, {fromBlock: block, toBlock: tx.receipt.blockNumber});
    await orderCompletedEvent.get(function(error, logs) {
      const event = logs.find(e => e.event === 'OrderCompleted')

      should.exist(event)

      event.args.uid.should.equal(uid)
      event.args.seller.should.equal(sellerInterface.address)
      event.args.buyer.should.equal(buyer)
      event.args.amount.should.be.bignumber.equal(buyerBalanceAfter.sub(buyerBalanceBefore))
      multisigBalanceAfter.sub(multisigBalanceBefore).should.be.bignumber.equal(event.args.amount.mul(0.01));
    })
  })

  it("enforces unique order ids", async function() {
    const uid = "-KlXQoew7-TCFB6o9ci-";
    const amount = ether(0.001);
    const price = 250;
    try {
      const tx = await sellerInterface.addOrder(uid, buyer, amount, price, "USD", {from: seller});
    } catch(error) {
      assertInvalidOpcode(error);
    }
  })

  it("prevents adding an order above availableBalance", async function() {
    const block = await web3.eth.blocknumber;
    const uid = "-ZlYQoel7-PCFB8o9ai-";
    const amount = await orderDb.availableBalances(sellerInterface.address);
    const price = 250;
    try {
      const tx = await sellerInterface.addOrder(uid, buyer, amount, price, "USD", {from: seller});
    } catch(error) {
      assertInvalidOpcode(error);
    }
  })

  it("prevents adding an order if the buyer address is a contract", async function() {
    const block = await web3.eth.blocknumber;
    const uid = "-ZlYQoel7-PCFB8o9ai-";
    const amount = ether(0.001);
    const contract = multisig.address;

    const price = 250;
    try {
      const tx = await sellerInterface.addOrder(uid, contract, amount, price, "USD", {from: seller});
    } catch(error) {
      assertInvalidOpcode(error);
    }
  })



});
