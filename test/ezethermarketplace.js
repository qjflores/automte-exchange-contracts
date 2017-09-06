var EZEtherMarketplace = artifacts.require("./EZEtherMarketplace.sol");
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


contract('EZEtherMarketplace', function(accounts) {
  var exchange, multisig;
  const owner = accounts[0];
  const owners = [accounts[0], accounts[3], accounts[4]];
  const seller = accounts[1];
  const buyer = accounts[2];

  const feePercent = 100; //100 = 1%, 1 = 0.01%

  it("creates exchange", async function() {
    exchange = await EZEtherMarketplace.new();

    multisig = await MultiSigWallet.new(owners, 3);
    await exchange.setFeeRecipient(multisig.address);
  });

  it("adding an order, seller is advertiser", async function() {
    const block = await web3.eth.blocknumber;
    const uid = "-KlXQoew7-TCFB6o9ci-";
    const amount = new BigNumber(ether(0.3));
    const fee = amount.mul(0.01);
    const price = 250;
    const currency = "USD"

    const tx = await exchange.addOrder(uid, buyer, amount, price, currency, seller, {from: seller, value: amount.add(fee)});

    const orderAddedEvent = exchange.OrderAdded({seller: seller}, {fromBlock: block, toBlock: tx.receipt.blockNumber});
    await orderAddedEvent.get(function(error, logs) {
      const event = logs.find(e => e.event === 'OrderAdded')

      should.exist(event)

      event.args.uid.should.equal(uid)
      event.args.seller.should.equal(seller)
      event.args.buyer.should.equal(buyer)
      event.args.amount.should.be.bignumber.equal(amount)
      event.args.price.should.be.bignumber.equal(price)
      event.args.currency.should.equal(currency)
    })
  })

  it("only seller can complete their order", async function() {
    const uid = "-KlXQoew7-TCFB6o9ci-";

    try {
      await exchange.completeOrder(uid, {from: owner});
    } catch(error) {
      assertInvalidOpcode(error);
    }
  })

  it("completing an order sends ether to buyer and fee to feeRecipient", async function() {

    const uid = "-KlXQoew7-TCFB6o9ci-";
    const amount = new BigNumber(ether(0.3));
    const fee = amount.mul(0.01);
    const block = await web3.eth.blocknumber;
    const buyerBalanceBefore = await web3.eth.getBalance(buyer);
    const multisigBalanceBefore = await web3.eth.getBalance(multisig.address);

    const tx = await exchange.completeOrder(uid, {from: seller});

    const multisigBalanceAfter = await web3.eth.getBalance(multisig.address);
    const buyerBalanceAfter = await web3.eth.getBalance(buyer);

    const orderCompletedEvent = exchange.OrderCompleted({seller: seller}, {fromBlock: block, toBlock: tx.receipt.blockNumber});
    await orderCompletedEvent.get(function(error, logs) {
      const event = logs.find(e => e.event === 'OrderCompleted')

      should.exist(event)

      event.args.uid.should.equal(uid)
      event.args.seller.should.equal(seller)
      event.args.buyer.should.equal(buyer)
      event.args.amount.should.be.bignumber.equal(buyerBalanceAfter.sub(buyerBalanceBefore))
      multisigBalanceAfter.sub(multisigBalanceBefore).should.be.bignumber.equal(fee);
    })
  })

  it("completing an order twice should throw", async function() {
    const uid = "-KlXQoew7-TCFB6o9ci-";
    try {
      await exchange.completeOrder(uid, {from: seller});
    } catch(error) {
      assertInvalidOpcode(error);
    }
  })

  it("enforces unique order ids", async function() {
    const uid = "-KlXQoew7-TCFB6o9ci-";
    const amount = new BigNumber(ether(0.001));
    const fee = amount.mul(0.01);
    const price = 250;
    try {
      await exchange.addOrder(uid, buyer, amount, price, "USD", seller, {from: seller, value: amount.add(fee)});
    } catch(error) {
      assertInvalidOpcode(error);
    }
  })

  it("prevents adding an order without enough msg.value", async function() {
    const block = await web3.eth.blocknumber;
    const uid = "-ZlYQoel7-PCFB8o9ai-";
    const amount = new BigNumber(ether(0.001));
    const price = 250;
    try {
      await exchange.addOrder(uid, buyer, amount, price, "USD", seller, {from: seller, value: amount});
    } catch(error) {
      assertInvalidOpcode(error);
    }
  })

  it("prevents adding an order if the buyer address is a contract", async function() {
    const block = await web3.eth.blocknumber;
    const uid = "-ZlYQoel7-PCFB8o9ai-";
    const amount = new BigNumber(ether(0.001));
    const fee = amount.mul(0.01);
    const contract = multisig.address;

    const price = 250;
    try {
      await exchange.addOrder(uid, contract, amount, price, "USD", seller, {from: seller, value: amount.add(fee)});
    } catch(error) {
      assertInvalidOpcode(error);
    }
  })



});
