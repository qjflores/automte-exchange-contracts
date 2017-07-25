pragma solidity ^0.4.11;

import "./zeppelin/ownership/Ownable.sol";
import "./SellerInterface.sol";
import "./OrderDB.sol";

contract DisputeInterface is Ownable {

  OrderDB orderDb;
  OrderBookI orderBook;

  function setOrderDb(address _orderDb) onlyOwner {
    orderDb = OrderDB(_orderDb);
  }

  function setDisputed(address _orderBook, string uid) onlyDisputeResolver {
    orderDb.setDisputed(_orderBook, uid);
  }

  function resolveDisputeSeller(string uid, address ethOrderBook) onlyDisputeResolver {
    orderDb.resolveDisputeSeller(ethOrderBook, uid);
  }

  function resolveDisputeBuyer(string uid, address ethOrderBook) onlyDisputeResolver {
    SellerInterface orderBook = SellerInterface(ethOrderBook);
    orderBook.completeOrder(uid);
  }

  modifier onlyDisputeResolver {
    require(msg.sender == orderDb.disputeResolver());
    _;
  }

  modifier checkOrderBook {
    require(orderDb.orderBook() != 0x0);
    if(orderDb.orderBook() != address(orderBook)) {
      orderBook = OrderBookI(orderDb.orderBook());
    }
    _;
  }

}
