pragma solidity ^0.4.11;

import "./OrderDBI.sol";
import "./zeppelin/ownership/Ownable.sol";

contract OrderDB is OrderDBI, Ownable {

  address public disputeResolver;

  mapping(address => address) specialFeeRecipient;

  function getFeeRecipient(address seller) constant returns (address) {
    if(specialFeeRecipient[seller] != address(0)) {
      return specialFeeRecipient[seller];
    }
    return feeRecipient;
  }

  function setFeeRecipient(address _feeRecipient) onlyOwner {
     feeRecipient = _feeRecipient;
  }

  function setDisputeInterface(address _disputeInterface) onlyOwner {
     disputeInterface = _disputeInterface;
  }

  function setDisputeResolver(address _disputeResolver) onlyOwner {
     disputeResolver = _disputeResolver;
  }

  mapping(address => uint256) specialFeeRates;

  function getFeePercent(address seller) constant returns (uint) {
    if(specialFeeRates[seller] > 0) {
      return specialFeeRates[seller];
    }
    return feePercent;
  }

  function setFeePercent(uint _feePercent) onlyOwner {
     feePercent = _feePercent;
  }

  function setSpecialFeePercent(address seller, uint _feePercent) onlyOwner {
     specialFeeRates[seller] = _feePercent;
  }

  mapping(address => uint) specialMinimumAmounts;
  mapping(address => uint) specialMaximumAmounts;
  uint minimumAmount;
  uint maximumAmount;

  function getMinAmount(address seller) constant returns (uint) {
    if(specialMinimumAmounts[seller] > 0) {
      return specialMinimumAmounts[seller];
    }
    return minimumAmount;
  }

  function getMaxAmount(address seller) constant returns (uint) {
    if(specialMaximumAmounts[seller] > 0) {
      return specialMaximumAmounts[seller];
    }
    return maximumAmount;
  }

  function setSpecialLimits(address seller, uint min, uint max) onlyOwner {
    require(min < max);
    specialMinimumAmounts[seller] = min;
    specialMaximumAmounts[seller] = max;
  }

  function setLimits(uint min, uint max) onlyOwner {
    require(min < max);
    minimumAmount = min;
    maximumAmount = max;
  }

  function setOrderBook(address _orderBook) onlyOwner {
    orderBook = _orderBook;
  }

  /*mapping(address => uint256) availableBalances;

  function getBalance(address seller) constant returns(uint256) {
    return availableBalances[seller];
  }

  function getBalance() constant returns(uint256) {
    return availableBalances[msg.sender];
  }*/

  function updateBalance(uint256 newBalance) {
    availableBalances[msg.sender] = newBalance;
    BalanceUpdated(msg.sender, newBalance);
  }

  function updateBalance(address seller, uint256 newBalance) onlyOrderBook external {
    availableBalances[seller] = newBalance;
    BalanceUpdated(seller, newBalance);
  }

  event BalanceUpdated(address sellerInterface, uint newBalance);

  struct Order {
    address buyer;
    uint amount;
    uint price;
    string currency;
    uint fee;
    OrderDBI.Status status;
  }

  mapping(address => mapping(string => Order)) orders;

  function addOrder(address seller, string uid, address buyer, uint amount, uint price, string currency, uint fee) onlyOrderBook external {
    orders[seller][uid].buyer = buyer;
    orders[seller][uid].amount = amount;
    orders[seller][uid].price = price;
    orders[seller][uid].currency = currency;
    orders[seller][uid].fee = fee;
    orders[seller][uid].status = OrderDBI.Status.Open;
  }

  function addOrder(string uid, address buyer, uint amount, uint price, string currency, uint fee) {
    orders[msg.sender][uid].buyer = buyer;
    orders[msg.sender][uid].amount = amount;
    orders[msg.sender][uid].price = price;
    orders[msg.sender][uid].currency = currency;
    orders[msg.sender][uid].fee = fee;
    orders[msg.sender][uid].status = OrderDBI.Status.Open;
  }

  function setStatus(string uid, OrderDBI.Status status) {
    orders[msg.sender][uid].status = status;
  }

  function setStatus(address seller, string uid, OrderDBI.Status status) onlyOrderBook external {
    orders[seller][uid].status = status;
  }

  function setDisputed(address orderBook, string uid) onlyDisputeInterface {
    require(orders[orderBook][uid].status == OrderDBI.Status.Open);
    orders[orderBook][uid].status = OrderDBI.Status.Disputed;
    OrderDisputed(orderBook, uid, orders[orderBook][uid].buyer);
  }

  event OrderDisputed(address orderBook, string uid, address buyer);

  function resolveDisputeSeller(address seller, string uid) onlyDisputeInterface {
    require(orders[seller][uid].status == OrderDBI.Status.Disputed);

    availableBalances[seller] += (orders[seller][uid].amount + orders[seller][uid].fee);
    orders[seller][uid].status = OrderDBI.Status.ResolvedSeller;
  }

  function getAmount(string uid) constant returns (uint) {
    return orders[msg.sender][uid].amount;
  }

  function getAmount(address seller, string uid) onlyOrderBook constant returns (uint) {
    return orders[seller][uid].amount;
  }

  function getFee(string uid) constant returns (uint) {
    return orders[msg.sender][uid].fee;
  }

  function getFee(address seller, string uid) onlyOrderBook constant returns (uint) {
    return orders[seller][uid].fee;
  }

  function getBuyer(string uid) constant returns (address) {
    return orders[msg.sender][uid].buyer;
  }

  function getBuyer(address seller, string uid) onlyOrderBook constant returns (address) {
    return orders[seller][uid].buyer;
  }

  function getStatus(string uid) constant returns (OrderDBI.Status) {
    return orders[msg.sender][uid].status;
  }

  function getStatus(address seller, string uid) onlyOrderBook constant returns (OrderDBI.Status) {
    return orders[seller][uid].status;
  }

  modifier onlyDisputeInterface {
    require(msg.sender == disputeInterface);
    _;
  }

}
