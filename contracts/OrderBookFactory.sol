pragma solidity ^0.4.11;

import "./ETHOrderBook.sol";
import "./zeppelin/ownership/Ownable.sol";

contract OrderBookFactory is Ownable {

  uint feePercent;
  address disputeResolver;

  function OrderBookFactory(address _disputeResolver) {
    feePercent = 1;
    disputeResolver = _disputeResolver;
  }

  //Only contracts whose addresses are logged by this event will appear on the exchange.
  event ETHOrderBookCreated(address indexed seller, address orderAddress);

  function createETHOrderBook(string country) external {
    ETHOrderBook orderBook = new ETHOrderBook(msg.sender, disputeResolver, country, feePercent);

    orderBook.transferOwnership(owner);

    ETHOrderBookCreated(msg.sender, orderBook);
  }

}
