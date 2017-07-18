pragma solidity ^0.4.11;

import "./ETHOrderBook.sol";
import "./zeppelin/ownership/Ownable.sol";

contract OrderBookFactory is Ownable {

  uint feePercent;
  address public disputeInterface;
  address public orderDb;

  function setDisputeInterface(address _disputeInterface) {
      disputeInterface = _disputeInterface;
  }

  function setOrderDb(address _orderDb) {
      orderDb = _orderDb;
  }

  function OrderBookFactory(address _disputeInterface, address _orderDb) {
    feePercent = 1;
    disputeInterface = _disputeInterface;
    orderDb = _orderDb;
  }

  //Only contracts whose addresses are logged by this event will appear on the exchange.
  event ETHOrderBookCreated(address indexed seller, address orderAddress);

  function createETHOrderBook(string country) external payable {
    ETHOrderBook orderBook = new ETHOrderBook(msg.sender, orderDb, disputeInterface, country, feePercent);

    orderBook.transferOwnership(owner);

    if(msg.value > 0) {
      orderBook.pay.value(msg.value)();
    }

    ETHOrderBookCreated(msg.sender, orderBook);
  }

}
