pragma solidity ^0.4.11;

contract OrderBookI {

  function addOrder(string uid, address buyer, uint amount, uint price, string currency);

  function completeOrder(string uid, address caller) payable;

}
