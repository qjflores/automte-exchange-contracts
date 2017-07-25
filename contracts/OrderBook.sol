pragma solidity ^0.4.11;

import "./zeppelin/math/SafeMath.sol";
import "./OrderDB.sol";
import "./OrderDBI.sol";
import "./OrderBookI.sol";

contract OrderBook is OrderBookI {
  using SafeMath for uint;

  OrderDBI orderDb;

  function OrderBook(address _orderDb) {
    orderDb = OrderDB(_orderDb);
  }

  function calculateFee(uint amount, address seller) returns (uint) {
    //((amount * 100) * feePercent) / 10000
    return ((amount.mul(100)).mul(orderDb.getFeePercent(seller))).div(1000000);
  }

  event OrderAdded(string uid, address seller, address buyer, uint amount, uint price, string currency, uint availableBalance);

  //called by seller via interface
  function addOrder(string uid, address buyer, uint amount, uint price, string currency) {
    uint fee = calculateFee(amount, msg.sender);

    require(
      (amount.add(fee) <= orderDb.availableBalances(msg.sender)) &&
      (amount >= orderDb.getMinAmount(msg.sender)) &&
      (amount <= orderDb.getMaxAmount(msg.sender)) &&
      (orderDb.getStatus(msg.sender, uid) == OrderDBI.Status.None)
      );

    //adds order and updates sender's balance in DB
    orderDb.addOrder(msg.sender, uid, buyer, amount, price, currency, fee);

    orderDb.updateBalance(msg.sender, orderDb.availableBalances(msg.sender).sub(amount.add(fee)));

    OrderAdded(uid, msg.sender, buyer, amount, price, currency, orderDb.availableBalances(msg.sender));
  }

  event OrderCompleted(string uid, address seller, address buyer, uint amount);
  event DisputeResolved(string uid, address seller, address buyer, string resolvedTo);

  //called by seller or arbiter via interface
  function completeOrder(string uid, address caller) payable {
    require(
      (orderDb.getStatus(msg.sender, uid) == OrderDBI.Status.Open || orderDb.getStatus(msg.sender, uid) == OrderDBI.Status.Disputed) &&
      (msg.value == orderDb.getAmount(msg.sender, uid).add(orderDb.getFee(msg.sender, uid)))
    );

    //arbiter can only call if order is in dispute
    if(caller == orderDb.disputeInterface()) {
      require(orderDb.getStatus(msg.sender, uid) == OrderDBI.Status.Disputed);
    }

    orderDb.getBuyer(msg.sender, uid).transfer(orderDb.getAmount(msg.sender, uid));
    orderDb.getFeeRecipient(msg.sender).transfer(orderDb.getFee(msg.sender, uid));

    if(orderDb.getStatus(msg.sender, uid) == OrderDBI.Status.Open) {
      orderDb.setStatus(msg.sender, uid, OrderDBI.Status.Complete);
      OrderCompleted(uid, msg.sender, orderDb.getBuyer(msg.sender, uid), orderDb.getAmount(msg.sender, uid));
    } else {
      orderDb.setStatus(msg.sender, uid, OrderDBI.Status.ResolvedBuyer);
      DisputeResolved(uid, msg.sender, orderDb.getBuyer(msg.sender, uid), 'buyer');
    }
  }

}
