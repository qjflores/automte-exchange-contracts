pragma solidity ^0.4.11;

import "./ETHOrderBook.sol";
import "./zeppelin/ownership/Ownable.sol";

/*
  owner of OrderFactory should be the OrderManager
*/
contract OrderBookFactory is Ownable {

  uint private feePercent;
  uint constant INIT_FEE_PERCENT = 1; //1%

  function OrderFactory() {
    feePercent = INIT_FEE_PERCENT;
  }

  //Only contracts whose addresses are logged by this event will appear on the exchange.
  event ETHOrderBookCreated(address seller, address orderAddress);

  function createETHOrderBook() external {
    ETHOrderBook orderBook = new ETHOrderBook(msg.sender, feePercent, 1 ether, 10 ether);

    orderBook.transferOwnership(owner);

    ETHOrderBookCreated(msg.sender, orderBook);
  }

}
