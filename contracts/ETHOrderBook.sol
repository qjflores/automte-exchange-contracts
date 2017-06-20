pragma solidity ^0.4.11;
//"-KkB0qMpH-dz7KTvPC9v", "0x5bF90665B051c36cE54388a487D1021F3fAdd999", "100000000000000000", 18000, "USD"
import "./zeppelin/ownership/Ownable.sol";
import "./zeppelin/SafeMath.sol";
import "../oraclize-ethereum-api/oraclizeAPI_0.4.sol";


library OrderBook {
  enum Status { Open, Complete, Disputed, ResolvedSeller, ResolvedBuyer }

  struct Order {
    address buyer;
    uint amount;
    uint price;
    string currency;
    uint fee;
    Status status;
  }

  struct Orders{ mapping(string => Order) orders; }

  function addOrder(Orders storage self, string uid, address buyer, uint amount, uint price, string currency, uint fee) {
    self.orders[uid].buyer = buyer;
    self.orders[uid].amount = amount;
    self.orders[uid].price = price;
    self.orders[uid].currency = currency;
    self.orders[uid].fee = fee;
    self.orders[uid].status = Status.Open;
  }
}

contract ETHOrderBook is Ownable, usingOraclize {
  using SafeMath for uint;

  OrderBook.Orders orderBook;
  address public seller;
  string country;
  uint public availableBalance;
  uint feePercent; // 1 = 1% fee
  address disputeResolver;

  uint MINIMUM_ORDER_AMOUNT; //inclusive
  uint MAXIMUM_ORDER_AMOUNT; //exclusive

  mapping(bytes32 => string) disputeQueryIds;

  function ETHOrderBook(address _seller, address _disputeResolver, string _country, uint _feePercent, uint min, uint max) {
    seller = _seller;
    disputeResolver = _disputeResolver;
    country = _country;
    feePercent = _feePercent;
    MINIMUM_ORDER_AMOUNT = min;
    MAXIMUM_ORDER_AMOUNT = max;
    availableBalance = 0;
  }

  event BalanceUpdated(uint availableBalance);
  function () payable {
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
      || amount <= MINIMUM_ORDER_AMOUNT //don't add order if amount is less than or equal to minimum order amount
      || amount > MAXIMUM_ORDER_AMOUNT //don't add order if amount is greater than maximum order amount
      || amount.add(fee) > availableBalance //don't add order if amount with fee exceeds available funds
      || orderBook.orders[uid].amount > 0 //don't add order if an order with the same UID already exists
    )
      throw;

    OrderBook.addOrder(orderBook, uid, buyer, amount, price, currency, fee);

    availableBalance = availableBalance.sub(amount.add(fee));

    OrderAdded(uid, seller, buyer, amount, price, currency, availableBalance);
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

  function checkDispute(string uid) onlyDisputeResolver statusIs(uid, OrderBook.Status.Open) {
    disputeQueryIds[oraclize_query("URL", "json(https://us-central1-automteetherexchange.cloudfunctions.net/checkDispute).dispute", strConcat('\n{"country" :"', country, '", "orderId": "', uid, '"}'))] = uid;
  }

  function __callback(bytes32 id, string result) {
    if(msg.sender != oraclize_cbAddress() || strCompare(disputeQueryIds[id], "VOID") == 0) throw;
    if(strCompare(result, "true") == 0) {
      orderBook.orders[disputeQueryIds[id]].status = OrderBook.Status.Disputed;
      OrderDisputed(disputeQueryIds[id], seller, orderBook.orders[disputeQueryIds[id]].buyer);
    }
    disputeQueryIds[id] = "VOID";
  }

  event DisputeResolved(string uid, address seller, address buyer, string resolvedTo);

  //Resolve dispute in favor of seller
  function resolveDisputeSeller(string uid) onlyDisputeResolver statusIs(uid, OrderBook.Status.Disputed) {
    availableBalance = availableBalance.add(orderBook.orders[uid].amount.add(orderBook.orders[uid].fee));

    orderBook.orders[uid].status = OrderBook.Status.ResolvedSeller;

    DisputeResolved(uid, seller, orderBook.orders[uid].buyer, 'seller');
  }

  //Resolve dispute in favor of buyer
  function resolveDisputeBuyer(string uid) onlyDisputeResolver statusIs(uid, OrderBook.Status.Disputed) {
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

  modifier onlyDisputeResolver() {
    if(msg.sender != disputeResolver)
      throw;
    _;
  }

}
