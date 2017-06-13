pragma solidity ^0.4.11;

import "./ETHOrderBook.sol";

contract DisputeResolver {

  // list of owners
  address[256] owners;
  // index on the list of owners to allow reverse lookup
  mapping(address => uint) ownerIndex;

  // simple single-sig function modifier.
  modifier onlyOwner {
    if (!isOwner(msg.sender)) {
      throw;
    }
    _;
  }

  //maps uid to assignee's address
  mapping(string => address) assignments;

  //maps uid to ETHOrderBook address
  mapping(string => address) disputes;

  function DisputeResolver(address[] _owners) {
    owners[1] = msg.sender;
    ownerIndex[msg.sender] = 1;
    for (uint i = 0; i < _owners.length; ++i) {
      owners[2 + i] = _owners[i];
      ownerIndex[_owners[i]] = 2 + i;
    }
  }

  event DisputeAssigned(address ethOrderBook, string uid, address assignee, address assigner);
  event DisputeChecked(address ethOrderBook, string uid, address assignee);
  event DisputeResolved(address ethOrderBook, string uid, string resolvedTo, address assignee);

  function assignDispute(address ethOrderBook, string uid, address assignee) onlyOwner {
    assignments[uid] = assignee;
    disputes[uid] = ethOrderBook;
    DisputeAssigned(ethOrderBook, uid, assignee, msg.sender);
  }

  function checkDispute(string uid) onlyAssignee(uid) {
    ETHOrderBook orderBook = ETHOrderBook(disputes[uid]);
    orderBook.checkDispute(uid);
    DisputeChecked(disputes[uid], uid, msg.sender);
  }

  function resolveDisputeSeller(string uid) onlyAssignee(uid) {
    ETHOrderBook orderBook = ETHOrderBook(disputes[uid]);
    orderBook.resolveDisputeSeller(uid);
    DisputeResolved(disputes[uid], uid, 'seller', msg.sender);
  }

  function resolveDisputeBuyer(string uid) onlyAssignee(uid) {
    ETHOrderBook orderBook = ETHOrderBook(disputes[uid]);
    orderBook.resolveDisputeBuyer(uid);
    DisputeResolved(disputes[uid], uid, 'buyer', msg.sender);
  }

  modifier onlyAssignee(string uid) {
    if(assignments[uid] != msg.sender)
      throw;
    _;
  }

  // Gets an owner by 0-indexed position (using numOwners as the count)
  function getOwner(uint ownerIndex) external constant returns (address) {
    return address(owners[ownerIndex + 1]);
  }

  function isOwner(address _addr) constant returns (bool) {
    return ownerIndex[_addr] > 0;
  }

}
