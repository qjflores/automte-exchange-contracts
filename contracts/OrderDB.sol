pragma solidity ^0.4.11;

import "./OrderDBI.sol";

contract OrderDB is OrderDBI {

  struct Order {
    address buyer;
    uint amount;
    uint price;
    string currency;
    uint fee;
    OrderDBI.Status status;
  }

  mapping(address => mapping(string => Order)) orders;

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

  function getAmount(string uid) constant returns (uint) {
    return orders[msg.sender][uid].amount;
  }

  function getFee(string uid) constant returns (uint) {
    return orders[msg.sender][uid].fee;
  }

  function getBuyer(string uid) constant returns (address) {
    return orders[msg.sender][uid].buyer;
  }

  function getStatus(string uid) constant returns (OrderDBI.Status) {
    return orders[msg.sender][uid].status;
  }

  function getStatus(address orderBook, string uid) constant returns (OrderDBI.Status) {
    return orders[orderBook][uid].status;
  }

  function getAmount(address orderBook, string uid) constant returns (uint) {
    return orders[orderBook][uid].amount;
  }

}
