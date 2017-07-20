pragma solidity ^0.4.11;

import "./zeppelin/ownership/Ownable.sol";
import "./ETHOrderBook.sol";
import "./OrderDB.sol";

contract DisputeInterface is Ownable {

  address public disputeResolver;
  bytes32 public queryId;
  OrderDB orderDb;

  function DisputeInterface() {
    disputeResolver = 0x0;
  }

  function setDisputeResolver(address _disputeResolver) onlyOwner {
    disputeResolver = _disputeResolver;
  }

  function setOrderDb(address _orderDb) onlyOwner {
    orderDb = OrderDB(_orderDb);
  }

  function setDisputed(address _orderBook, string uid) onlyDisputeResolver {
    orderDb.setDisputed(_orderBook, uid);
  }

  function resolveDisputeSeller(string uid, address ethOrderBook) onlyDisputeResolver {
    ETHOrderBook orderBook = ETHOrderBook(ethOrderBook);
    orderBook.resolveDisputeSeller(uid);
  }

  function resolveDisputeBuyer(string uid, address ethOrderBook) onlyDisputeResolver {
    ETHOrderBook orderBook = ETHOrderBook(ethOrderBook);
    orderBook.completeOrder(uid);
  }

  modifier onlyDisputeResolver {
    if(msg.sender != disputeResolver)
      throw;
    _;
  }

}
