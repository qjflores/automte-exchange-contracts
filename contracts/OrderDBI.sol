pragma solidity ^0.4.11;

contract OrderDBI {
  address public feeRecipient;
  uint public feePercent;
  address public disputeInterface;
  address public orderBook;
  enum Status { None, Open, Complete, Disputed, ResolvedSeller, ResolvedBuyer }

  function addOrder(string uid, address buyer, uint amount, uint price, string currency, uint fee);
  function addOrder(address seller, string uid, address buyer, uint amount, uint price, string currency, uint fee) onlyOrderBook external;
  function setStatus(string uid, Status status);

  function getAmount(string uid) constant returns (uint);
  function getFee(string uid) constant returns (uint);
  function getBuyer(string uid) constant returns (address);
  function getStatus(string uid) constant returns (Status);
  function getFeePercent(address seller) constant returns (uint);
  function getFeeRecipient(address seller) constant returns (address);
  function getMinAmount(address seller) constant returns (uint);
  function getMaxAmount(address seller) constant returns (uint);

  function getAmount(address seller, string uid) onlyOrderBook constant returns (uint);
  function getFee(address seller, string uid) onlyOrderBook constant returns (uint);
  function getBuyer(address seller, string uid) onlyOrderBook constant returns (address);
  function getStatus(address seller, string uid) onlyOrderBook constant returns (Status);
  function setStatus(address seller, string uid, Status status) onlyOrderBook external;

  /*function getBalance(address seller) constant returns(uint256);
  function getBalance() constant returns(uint256);*/

  mapping(address => uint256) public availableBalances;

  function updateBalance(uint256 newBalance);
  function updateBalance(address seller, uint256 newBalance) onlyOrderBook external;

  modifier onlyOrderBook {
    require(msg.sender == orderBook);
    _;
  }
}
