pragma solidity ^0.4.11;

import "./SellerInterface.sol";
import "./zeppelin/ownership/Ownable.sol";

contract SellerInterfaceFactory is Ownable {

  address public orderDb;

  function setOrderDb(address _orderDb) onlyOwner {
    orderDb = _orderDb;
  }

  function SellerInterfaceFactory(address _orderDb) {
    orderDb = _orderDb;
  }

  //Only contracts whose addresses are logged by this event will appear on the exchange.
  event SellerInterfaceCreated(address indexed seller, address orderAddress);

  function createSellerInterface() external payable {
    SellerInterface sellerInterface = new SellerInterface(msg.sender, orderDb);

    if(msg.value > 0) {
      sellerInterface.deposit.value(msg.value)();
    }

    SellerInterfaceCreated(msg.sender, sellerInterface);
  }

  function createSellerInterface(address seller) external payable {
    SellerInterface sellerInterface = new SellerInterface(seller, orderDb);

    if(msg.value > 0) {
      sellerInterface.deposit.value(msg.value)();
    }

    SellerInterfaceCreated(seller, sellerInterface);
  }

}
