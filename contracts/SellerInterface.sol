pragma solidity ^0.4.11;

import "./OrderDBI.sol";
import "./OrderBookI.sol";

contract SellerInterface {

  function isContract(address addr) returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

  OrderDBI orderDb;
  OrderBookI orderBook;
  address public seller;

  function SellerInterface(address _seller, address _orderDb) {
    seller = _seller;
    orderDb = OrderDBI(_orderDb);
    orderBook = OrderBookI(orderDb.orderBook());
  }

  //Updates balance in DB
  function deposit() payable {
    orderDb.updateBalance(orderDb.availableBalances(this) + msg.value);
  }

  //Adds order info to DB, updates balance
  function addOrder(string uid, address buyer, uint amount, uint price, string currency) checkOrderBook onlySeller {
    require(!isContract(buyer));
    orderBook.addOrder(uid, buyer, amount, price, currency);
  }

  //Pays out to buyer, updates DB
  function completeOrder(string uid) checkOrderBook {
    require(msg.sender == seller || msg.sender == orderDb.disputeInterface());
    uint256 balanceBefore = orderDb.getBuyer(uid).balance;
    orderBook.completeOrder.value(orderDb.getAmount(uid) + orderDb.getFee(uid))(uid, msg.sender);

    assert(orderDb.getBuyer(uid).balance == balanceBefore + orderDb.getAmount(uid));
  }

  //Transfers ether back to seller, updates DB
  function withdraw(uint amount) onlySeller {
    require(amount <= orderDb.availableBalances(this));
    seller.transfer(amount);
    orderDb.updateBalance(orderDb.availableBalances(this) - amount);
  }

  modifier checkOrderBook {
    require(orderDb.orderBook() != 0x0);
    if(orderDb.orderBook() != address(orderBook)) {
      orderBook = OrderBookI(orderDb.orderBook());
    }
    _;
  }

  modifier onlySeller {
    require(msg.sender == seller);
    _;
  }

}
