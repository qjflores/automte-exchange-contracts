var ETHOrderBookMock = artifacts.require("./ETHOrderBookMock.sol");
var DisputeResolverMock = artifacts.require("./DisputeResolverMock.sol");

const assertInvalidOpcode = require('./helpers/assertInvalidOpcode');

const ether = function(amount) {
  return web3.toWei(amount, 'ether');
}


contract('DisputeResolverMock', function(accounts) {
  var ethOrderBook, disputeResolver;
  var owner = accounts[0];
  var owners = [accounts[0], accounts[3], accounts[4]];
  var seller = accounts[1];
  var buyer = accounts[2];
  var assignee = accounts[5];
  var min = ether(0.2);
  var max = ether(5);
  var country = "IN";

  const feePercent = 0.01;

  it("creates ETHOrderBook with availableBalance of 0", async function() {
    disputeResolver = await DisputeResolverMock.new(owners);
    ethOrderBook = await ETHOrderBookMock.new(seller, disputeResolver.address, country, 1, min, max, {from: owner});
    assert.equal(await ethOrderBook.availableBalance(), 0);
  });

  it("sending ETH updates available balance", async function() {
    await web3.eth.sendTransaction({from: seller, to: ethOrderBook.address, value: ether(1)})
    assert.equal(await ethOrderBook.availableBalance(), ether(1));
  })

  it("adding order from seller updates availableBalance", async function() {
    let availableBalance = web3.fromWei(await ethOrderBook.availableBalance(), 'ether');
    let contractBalance = await web3.eth.getBalance(ethOrderBook.address);
    await ethOrderBook.addOrder("-1234", buyer, ether(0.5), 11015, "USD", {from: seller});
    assert.equal(await ethOrderBook.availableBalance(), ether(availableBalance - (0.5+(0.5*feePercent))));
    //actual balance shouldn't change
    assert( (await web3.eth.getBalance(ethOrderBook.address)).equals(contractBalance) );
  })

  if("only disputeResolver can checkDispute", async function() {
    try {
      await ethOrderBook.checkDispute("-1234");
    } catch(error) {
      assertInvalidOpcode(error);
    }
  });

  it("assignee can check a dispute", async function() {
    await disputeResolver.assignDispute(ethOrderBook.address, "-1234", assignee);
    await disputeResolver.checkDispute("-1234", {from: assignee});
    //should be an error because order is now disputed
    try {
      await ethOrderBook.completeOrder("-1234", {from: seller});
    } catch(error) {
      assertInvalidOpcode(error);
    }
  })

  it("resolving order to buyer sends ether to buyer and fee to owner", async function() {
    let buyerBalance = await web3.eth.getBalance(buyer);
    let ownerBalance = await web3.eth.getBalance(owner);
    let contractBalance = await web3.eth.getBalance(ethOrderBook.address);
    await disputeResolver.resolveDisputeBuyer("-1234", {from: assignee});
    assert( (await web3.eth.getBalance(buyer)).equals(buyerBalance.plus(ether(0.5))) )
    assert( (await web3.eth.getBalance(owner)).equals(ownerBalance.plus(ether(0.5*feePercent))) )
    assert( (await web3.eth.getBalance(ethOrderBook.address)).equals(contractBalance.minus(ether(0.5+0.5*feePercent))) )
  })

  //
  // it("prevents double spending (completing same order twice)", async function() {
  //   try {
  //     await ethOrderBook.completeOrder("-1234", {from: seller});
  //   } catch(error) {
  //     assertInvalidOpcode(error);
  //   }
  // })
  //
  // it("enforces unique order ids", async function() {
  //   try {
  //     await ethOrderBook.addOrder("-1234", buyer, ether(0.1), 11015, "USD", {from: seller});
  //   } catch(error) {
  //     assertInvalidOpcode(error);
  //   }
  // });
  //
  // it("enforces minimum/maximum order amounts", async function() {
  //   await web3.eth.sendTransaction({from: seller, to: ethOrderBook.address, value: ether(6)})
  //   try {
  //     await ethOrderBook.addOrder("x234a", buyer, ether(5.01), 11015, "USD", {from: seller});
  //   } catch(error) {
  //     assertInvalidOpcode(error);
  //   }
  //   try {
  //     await ethOrderBook.addOrder("x234a", buyer, ether(0.19), 11015, "USD", {from: seller});
  //   } catch(error) {
  //     assertInvalidOpcode(error);
  //   }
  //   await ethOrderBook.addOrder("x234a", buyer, ether(5), 11015, "USD", {from: seller});
  // })

});
