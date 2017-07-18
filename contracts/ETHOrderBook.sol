pragma solidity ^0.4.11;

import "./zeppelin/ownership/Ownable.sol";
import "./zeppelin/SafeMath.sol";
import "./OrderDBI.sol";

contract ETHOrderBook is Ownable {
  using SafeMath for uint;

  OrderDBI orderDb;
  address public seller;
  string country;
  uint public availableBalance;
  uint feePercent; // 1 = 1% fee
  address disputeResolver;

//   uint MINIMUM_ORDER_AMOUNT; //inclusive
//   uint MAXIMUM_ORDER_AMOUNT; //exclusive

  mapping(bytes32 => string) disputeQueryIds;

  function ETHOrderBook(address _seller, address _orderDb, address _disputeResolver, string _country, uint _feePercent) {
    seller = _seller;
    orderDb = OrderDBI(_orderDb);
    disputeResolver = _disputeResolver;
    country = _country;
    feePercent = _feePercent;
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
    return ((amount.mul(100)).mul(feePercent)).div(10000);
  }

  event OrderAdded(string uid, address seller, address buyer, uint amount, uint price, string currency, uint availableBalance);

  function addOrder(string uid, address buyer, uint amount, uint price, string currency) {
    uint fee = calculateFee(amount);

    if(
         msg.sender != seller //only seller can add orders
    //   || amount <= MINIMUM_ORDER_AMOUNT //don't add order if amount is less than or equal to minimum order amount
    //   || amount > MAXIMUM_ORDER_AMOUNT //don't add order if amount is greater than maximum order amount
      || amount.add(fee) > availableBalance //don't add order if amount with fee exceeds available funds
      || orderDb.getAmount(uid) > 0 //don't add order if an order with the same UID already exists
    )
      throw;

    orderDb.addOrder(uid, buyer, amount, price, currency, fee);

    availableBalance = availableBalance.sub(amount.add(fee));

    OrderAdded(uid, seller, buyer, amount, price, currency, availableBalance);
  }

  event OrderCompleted(string uid, address seller, address buyer, uint amount);

  function completeOrder(string uid) onlySeller statusIs(uid, OrderDBI.Status.Open) {
    if(!orderDb.getBuyer(uid).send(orderDb.getAmount(uid)))
      throw;

    if(!owner.send(orderDb.getFee(uid)))
      throw;

    OrderCompleted(uid, seller, orderDb.getBuyer(uid), orderDb.getAmount(uid));

    orderDb.setStatus(uid, OrderDBI.Status.Complete);
  }

  event OrderDisputed(string uid, address seller, address buyer);

  function setDisputed(string uid) onlyDisputeResolver statusIs(uid, OrderDBI.Status.Open) {
    orderDb.setStatus(uid, OrderDBI.Status.Disputed);
    OrderDisputed(uid, seller, orderDb.getBuyer(uid));
  }

  event DisputeResolved(string uid, address seller, address buyer, string resolvedTo);

  //Resolve dispute in favor of seller
  function resolveDisputeSeller(string uid) onlyDisputeResolver statusIs(uid, OrderDBI.Status.Disputed) {
    availableBalance = availableBalance.add(orderDb.getAmount(uid).add(orderDb.getFee(uid)));

    orderDb.setStatus(uid, OrderDBI.Status.ResolvedSeller);

    DisputeResolved(uid, seller, orderDb.getBuyer(uid), 'seller');
  }

  //Resolve dispute in favor of buyer
  function resolveDisputeBuyer(string uid) onlyDisputeResolver statusIs(uid, OrderDBI.Status.Disputed) {
    if(!orderDb.getBuyer(uid).send(orderDb.getAmount(uid)))
      throw;

    if(!owner.send(orderDb.getFee(uid)))
      throw;

    orderDb.setStatus(uid, OrderDBI.Status.ResolvedBuyer);

    DisputeResolved(uid, seller, orderDb.getBuyer(uid), 'buyer');
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

  modifier statusIs(string uid, OrderDBI.Status status) {
    if(orderDb.getStatus(uid) != status)
      throw;
    _;
  }

  modifier onlySeller() {
    if(msg.sender != seller)
      throw;
    _;
  }

  modifier onlyDisputeResolver() {
    if(msg.sender != disputeResolver)
      throw;
    _;
  }

}
