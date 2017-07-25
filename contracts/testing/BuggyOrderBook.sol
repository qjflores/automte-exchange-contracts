pragma solidity ^0.4.11;

import "../OrderBookI.sol";

contract BuggyOrderBook is OrderBookI {


  event BuggedEvent(string uid);
  function addOrder(string uid, address buyer, uint amount, uint price, string currency) {
    BuggedEvent(uid);
  }

  function completeOrder(string uid, address caller) payable {
    BuggedEvent(uid);
  }

}
