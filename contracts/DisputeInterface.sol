pragma solidity ^0.4.11;

import "./zeppelin/ownership/Ownable.sol";
import "./ETHOrderBook.sol";

contract DisputeInterface is Ownable {

  address disputeResolver;

  function DisputeInterface() {
    disputeResolver = 0x0;
  }

  function setDisputeResolver(address _disputeResolver) onlyOwner {
    disputeResolver = _disputeResolver;
  }

  function checkDispute(string uid, address ethOrderBook) onlyDisputeResolver {
    ETHOrderBook orderBook = ETHOrderBook(ethOrderBook);
    orderBook.checkDispute(uid);
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
