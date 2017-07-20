pragma solidity ^0.4.11;

import "./ETHOrderBook.sol";
import "./zeppelin/ownership/Ownable.sol";

contract OrderBookFactory is Ownable {

  uint feePercent;
  address public orderDb;

  function setOrderDb(address _orderDb) onlyOwner {
      orderDb = _orderDb;
  }

  function OrderBookFactory(address _orderDb) {
    feePercent = 1;
    orderDb = _orderDb;
  }

  //Only contracts whose addresses are logged by this event will appear on the exchange.
  event ETHOrderBookCreated(address indexed seller, address orderAddress);

  function createETHOrderBook(string country) external payable {
    ETHOrderBook orderBook = new ETHOrderBook(msg.sender, orderDb);

    if(msg.value > 0) {
      orderBook.pay.value(msg.value)();
    }

    ETHOrderBookCreated(msg.sender, orderBook);
  }

}
