pragma solidity ^0.4.11;

import "./zeppelin/ownership/Ownable.sol";
import "./ETHOrderBook.sol";

contract DisputeInterface is Ownable {

  address public disputeResolver;
  bytes32 public queryId;

  function DisputeInterface() {
    disputeResolver = 0x0;
  }

  function setDisputeResolver(address _disputeResolver) onlyOwner {
    disputeResolver = _disputeResolver;
  }

  function setDisputed(address _orderBook, string uid) onlyDisputeResolver {
    ETHOrderBook orderBook = ETHOrderBook(_orderBook);
    orderBook.setDisputed(uid);
  }

  function resolveDisputeSeller(string uid, address ethOrderBook) onlyDisputeResolver {
    ETHOrderBook orderBook = ETHOrderBook(ethOrderBook);
    orderBook.resolveDisputeSeller(uid);
  }

  function resolveDisputeBuyer(string uid, address ethOrderBook) onlyDisputeResolver {
    ETHOrderBook orderBook = ETHOrderBook(ethOrderBook);
    orderBook.resolveDisputeBuyer(uid);
  }

  modifier onlyDisputeResolver {
    if(msg.sender != disputeResolver)
      throw;
    _;
  }

}
