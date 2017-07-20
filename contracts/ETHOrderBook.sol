pragma solidity ^0.4.11;

import "./zeppelin/SafeMath.sol";
import "./OrderDBI.sol";

contract ETHOrderBook {
  using SafeMath for uint;

  OrderDBI orderDb;
  address public seller;
  uint public availableBalance;

//   uint MINIMUM_ORDER_AMOUNT; //inclusive
//   uint MAXIMUM_ORDER_AMOUNT; //exclusive

  function ETHOrderBook(address _seller, address _orderDb) {
    seller = _seller;
    orderDb = OrderDBI(_orderDb);
    // MINIMUM_ORDER_AMOUNT = min;
    // MAXIMUM_ORDER_AMOUNT = max;
    availableBalance = 0;
  }

  event BalanceUpdated(uint availableBalance);

  function () payable {
    //Is there a reason to limit this to only the seller's address?
    //availableBalance += msg.value;
    availableBalance = availableBalance.add(msg.value);
    BalanceUpdated(availableBalance);
  }

  function pay() payable {
    //Is there a reason to limit this to only the seller's address?
    //availableBalance += msg.value;
    availableBalance = availableBalance.add(msg.value);
    BalanceUpdated(availableBalance);
  }


  function calculateFee(uint amount) returns (uint) {
    //((amount * 100) * feePercent) / 10000
    return ((amount.mul(100)).mul(orderDb.feePercent())).div(10000);
  }

  event OrderAdded(string uid, address seller, address buyer, uint amount, uint price, string currency, uint availableBalance);

  function addOrder(string uid, address buyer, uint amount, uint price, string currency) {
    uint fee = calculateFee(amount);

    require(
         msg.sender == seller //only seller can add orders
    //   || amount <= MINIMUM_ORDER_AMOUNT //don't add order if amount is less than or equal to minimum order amount
    //   || amount > MAXIMUM_ORDER_AMOUNT //don't add order if amount is greater than maximum order amount
      && amount.add(fee) <= availableBalance //don't add order if amount with fee exceeds available funds
      && orderDb.getAmount(uid) == 0 //don't add order if an order with the same UID already exists
    );

    orderDb.addOrder(uid, buyer, amount, price, currency, fee);

    availableBalance = availableBalance.sub(amount.add(fee));

    OrderAdded(uid, seller, buyer, amount, price, currency, availableBalance);
  }

  event OrderCompleted(string uid, address seller, address buyer, uint amount);
  event DisputeResolved(string uid, address seller, address buyer, string resolvedTo);

  function completeOrder(string uid) {
    require(
      (msg.sender == seller && (orderDb.getStatus(uid) == OrderDBI.Status.Open || orderDb.getStatus(uid) == OrderDBI.Status.Disputed)) ||
      (msg.sender == orderDb.disputeInterface() && orderDb.getStatus(uid) == OrderDBI.Status.Disputed)
    );

    orderDb.getBuyer(uid).transfer(orderDb.getAmount(uid));
    orderDb.feeRecipient().transfer(orderDb.getFee(uid));

    if(orderDb.getStatus(uid) == OrderDBI.Status.Open) {
      orderDb.setStatus(uid, OrderDBI.Status.Complete);
      OrderCompleted(uid, seller, orderDb.getBuyer(uid), orderDb.getAmount(uid));
    } else {
      orderDb.setStatus(uid, OrderDBI.Status.ResolvedBuyer);
      DisputeResolved(uid, seller, orderDb.getBuyer(uid), 'buyer');
    }
  }

  function resolveDisputeSeller(string uid) {
    require(msg.sender == orderDb.disputeInterface() && orderDb.getStatus(uid) == OrderDBI.Status.Disputed);

    availableBalance = availableBalance.add(orderDb.getAmount(uid).add(orderDb.getFee(uid)));

    orderDb.setStatus(uid, OrderDBI.Status.ResolvedSeller);

    DisputeResolved(uid, seller, orderDb.getBuyer(uid), 'seller');
  }

  function withdraw(uint amount) {
    require(msg.sender == seller && amount <= availableBalance);

    seller.transfer(amount);

    availableBalance = availableBalance.sub(amount);
  }

}
