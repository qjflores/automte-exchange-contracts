pragma solidity ^0.4.11;

import "./ETHOrderBook.sol";
import "./zeppelin/ownership/Ownable.sol";

/*
  owner of OrderFactory should be the OrderManager
*/
contract OrderBookFactory is Ownable {

  uint public feePercent;

  function OrderBookFactory() {
    feePercent = 1;
  }

  //Only contracts whose addresses are logged by this event will appear on the exchange.
  event ETHOrderBookCreated(address seller, address orderAddress);

  function createETHOrderBook(string country) external {
    ETHOrderBook orderBook = new ETHOrderBook(msg.sender, country, feePercent, 0.001 ether, 5 ether);

    orderBook.transferOwnership(owner);

    ETHOrderBookCreated(msg.sender, orderBook);
  }

}
