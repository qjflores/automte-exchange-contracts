pragma solidity ^0.4.11;

contract OrderDBI {
  address public feeRecipient;
  uint public feePercent;
  address public disputeInterface;
  enum Status { None, Open, Complete, Disputed, ResolvedSeller, ResolvedBuyer }

  function addOrder(string uid, address buyer, uint amount, uint price, string currency, uint fee);
  function setStatus(string uid, Status status);

  function getAmount(string uid) constant returns (uint);
  function getFee(string uid) constant returns (uint);
  function getBuyer(string uid) constant returns (address);
  function getStatus(string uid) constant returns (Status);
}
