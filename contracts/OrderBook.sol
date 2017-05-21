pragma solidity ^0.4.11;

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
