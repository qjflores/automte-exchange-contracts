pragma solidity ^0.4.11;

import "./zeppelin/ownership/Ownable.sol";
import "./zeppelin/SafeMath.sol";
import "./OrderBook.sol";

contract ETHOrderBook is Ownable {
  using SafeMath for uint;

  OrderBook.Orders orderBook;
  address public seller;
  uint public availableBalance;
  uint feePercent; // 1 = 1% fee

  uint MINIMUM_ORDER_AMOUNT; //inclusive
  uint MAXIMUM_ORDER_AMOUNT; //exclusive

  function ETHOrderBook(address _seller, uint _feePercent, uint min, uint max) {
    seller = _seller;
    feePercent = _feePercent;
    MINIMUM_ORDER_AMOUNT = min;
    MAXIMUM_ORDER_AMOUNT = max;
    availableBalance = 0;
  }

  function () payable {
    //Is there a reason to limit this to only the seller's address?
    availableBalance += msg.value;
  }


  function calculateFee(uint amount) returns (uint) {
    //((amount * 100) * feePercent) / 10000
    return ((amount.mul(100)).mul(feePercent)).div(10000);
  }

  event OrderAdded(string uid, address seller, address buyer, uint amount, uint price, string currency);

  function addOrder(string uid, address buyer, uint amount, uint price, string currency) {
    uint fee = calculateFee(amount);

    if(
         msg.sender != seller //only seller can add orders
      || amount <= MINIMUM_ORDER_AMOUNT //don't add order if amount is less than or equal to minimum order amount
      || amount > MAXIMUM_ORDER_AMOUNT //don't add order if amount is greater than maximum order amount
      || amount.add(fee) > availableBalance //don't add order if amount with fee exceeds available funds
      || orderBook.orders[uid].amount > 0 //don't add order if an order with the same UID already exists
    )
      throw;

    OrderBook.addOrder(orderBook, uid, buyer, amount, price, currency, fee);

    availableBalance = availableBalance.sub(amount.add(fee));

    OrderAdded(uid, seller, buyer, amount, price, currency);
  }

  event OrderCompleted(string uid, address seller, address buyer, uint amount);

  function completeOrder(string uid) onlySeller statusIs(uid, OrderBook.Status.Open) {
    if(!orderBook.orders[uid].buyer.send(orderBook.orders[uid].amount))
      throw;

    if(!owner.send(orderBook.orders[uid].fee))
      throw;

    OrderCompleted(uid, seller, orderBook.orders[uid].buyer, orderBook.orders[uid].amount);

    orderBook.orders[uid].status = OrderBook.Status.Complete;
  }

  event OrderDisputed(string uid, address seller, address buyer);

  function checkDispute(string uid) onlyOwner statusIs(uid, OrderBook.Status.Open) {
    //TODO: Use Oraclize to make an https request to firebase to check if the order is in dispute
    //bool disputed = oraclize.call('https://us-central1-automteetherexchange.cloudfunctions.net/isDisputed', uid)
    //if(disputed) orders[uid].status = OrderBook.Status.Disputed;
    //OrderDisputed(uid, seller, orders[uid].buyer)

    //for current testing, this function always mocks a true result
    orderBook.orders[uid].status = OrderBook.Status.Disputed;
    OrderDisputed(uid, seller, orderBook.orders[uid].buyer);
  }

  event DisputeResolved(string uid, address seller, address buyer, string resolvedTo);

  //Resolve dispute in favor of seller
  function resolveDisputeSeller(string uid) onlyOwner statusIs(uid, OrderBook.Status.Disputed) {
    availableBalance = availableBalance.add(orderBook.orders[uid].amount.add(orderBook.orders[uid].fee));

    orderBook.orders[uid].status = OrderBook.Status.ResolvedSeller;

    DisputeResolved(uid, seller, orderBook.orders[uid].buyer, 'seller');
  }

  //Resolve dispute in favor of buyer
  function resolveDisputeBuyer(string uid) onlyOwner statusIs(uid, OrderBook.Status.Disputed) {
    if(!orderBook.orders[uid].buyer.send(orderBook.orders[uid].amount))
      throw;

    if(!owner.send(orderBook.orders[uid].fee))
      throw;

    orderBook.orders[uid].status = OrderBook.Status.ResolvedBuyer;

    DisputeResolved(uid, seller, orderBook.orders[uid].buyer, 'buyer');
  }

  function withdraw(uint amount) onlySeller {
    if(amount > availableBalance)
      throw;

    if(!seller.send(amount)) {
      throw;
    } else {
      availableBalance = availableBalance.sub(amount);
    }
  }

  modifier statusIs(string uid, OrderBook.Status status) {
    if(orderBook.orders[uid].status != status)
      throw;
    _;
  }

  modifier onlySeller() {
    if(msg.sender != seller)
      throw;
    _;
  }

}
