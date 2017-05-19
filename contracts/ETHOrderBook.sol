pragma solidity ^0.4.11;

import "./zeppelin/ownership/Ownable.sol";
import "./zeppelin/SafeMath.sol";

contract ETHOrderBook is Ownable {
  using SafeMath for uint;

  enum Status { Open, Complete, Disputed, ResolvedSeller, ResolvedBuyer }

  struct Order {
    address buyer;
    uint amount;
    uint price;
    string currency;
    uint fee;
    Status status;
  }

  mapping(string => Order) orders;

  address public seller;
  uint public availableFunds;
  uint feePercent;

  uint MINIMUM_ORDER_AMOUNT; //inclusive
  uint MAXIMUM_ORDER_AMOUNT; //exclusive

  function ETHOrderBook(address _seller, uint _feePercent, uint min, uint max) {
    seller = _seller;

    if(_feePercent < 1 || _feePercent > 100)
      throw;
    feePercent = _feePercent;

    if(min == 0 || min > max)
      throw;
    MINIMUM_ORDER_AMOUNT = min;
    MAXIMUM_ORDER_AMOUNT = max;

    availableFunds = 0;
  }

  function () payable {
    availableFunds += msg.value;
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
      || (amount+fee) > availableFunds //don't add order if amount with fee exceeds available funds
      || orders[uid].amount > 0 //don't add order if an order with the same UID already exists
    )
      throw;

    orders[uid].buyer = buyer;
    orders[uid].amount = amount;
    orders[uid].price = price;
    orders[uid].currency = currency;
    orders[uid].fee = fee;
    orders[uid].status = Status.Open;

    availableFunds -= (amount+fee);

    OrderAdded(uid, seller, buyer, amount, price, currency);
  }

  event OrderCompleted(string uid, address seller, address buyer, uint amount);

  function completeOrder(string uid) onlySeller statusIs(uid, Status.Open) {
    if(!orders[uid].buyer.send(orders[uid].amount))
      throw;

    if(!owner.send(orders[uid].fee))
      throw;

    OrderCompleted(uid, seller, orders[uid].buyer, orders[uid].amount);

    orders[uid].status = Status.Complete;
  }

  event OrderDisputed(string uid, address seller, address buyer);

  function checkDispute(string uid) onlyOwner statusIs(uid, Status.Open) {
    //TODO: Use Oraclize to make an https request to firebase to check if the order is in dispute
    //bool disputed = oraclize.call('https://us-central1-automteetherexchange.cloudfunctions.net/isDisputed', uid)
    //if(disputed) orders[uid].status = Status.Disputed;
    //OrderDisputed(uid, seller, orders[uid].buyer)

    //for current testing, this function always mocks a true result
    orders[uid].status = Status.Disputed;
    OrderDisputed(uid, seller, orders[uid].buyer);
  }

  event DisputeResolved(string uid, address seller, address buyer, string resolvedTo);

  //Resolve dispute in favor of seller
  function resolveDisputeSeller(string uid) onlyOwner statusIs(uid, Status.Disputed) {
    availableFunds += orders[uid].amount + orders[uid].fee;

    orders[uid].status = Status.ResolvedSeller;

    DisputeResolved(uid, seller, orders[uid].buyer, 'seller');
  }

  //Resolve dispute in favor of buyer
  function resolveDisputeBuyer(string uid) onlyOwner statusIs(uid, Status.Disputed) {
    if(!orders[uid].buyer.send(orders[uid].amount))
      throw;

    if(!owner.send(orders[uid].fee))
      throw;

    orders[uid].status = Status.ResolvedBuyer;

    DisputeResolved(uid, seller, orders[uid].buyer, 'buyer');
  }

  function withdraw(uint amount) onlySeller {
    if(amount > availableFunds)
      throw;

    if(!seller.send(amount))
      throw;
  }

  modifier statusIs(string uid, Status status) {
    if(orders[uid].status != status)
      throw;
    _;
  }

  modifier onlySeller() {
    if(msg.sender != seller)
      throw;
    _;
  }

}
