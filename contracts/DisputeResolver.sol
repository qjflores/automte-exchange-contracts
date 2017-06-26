pragma solidity ^0.4.11;

import "./ETHOrderBook.sol";
import "./DisputeInterface.sol";

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

  enum Status { Assigned, ResolvedSeller, ResolvedBuyer }

  struct Dispute {
    address assignee;
    address ethOrderBook;
    Status status;
  }

  //maps uid to Dispute
  mapping(string => Dispute) disputes;

  DisputeInterface disputeInterface;

  function DisputeResolver(address[] _owners, address _disputeInterface) {
    owners[1] = msg.sender;
    ownerIndex[msg.sender] = 1;
    for (uint i = 0; i < _owners.length; ++i) {
      owners[2 + i] = _owners[i];
      ownerIndex[_owners[i]] = 2 + i;
    }

    disputeInterface = DisputeInterface(_disputeInterface);
  }

  event DisputeAssigned(address ethOrderBook, string uid, address assignee, address assigner);
  event DisputeEscalated(address ethOrderBook, string uid, address assignee, address assigner);
  event DisputeResolved(address ethOrderBook, string uid, string resolvedTo, address assignee);

  function assignDispute(address ethOrderBook, string uid, address assignee) onlyOwner {
    disputes[uid].assignee = assignee;
    disputes[uid].ethOrderBook = ethOrderBook;
    disputes[uid].status = Status.Assigned;
    disputeInterface.checkDispute(uid, ethOrderBook);
    DisputeAssigned(ethOrderBook, uid, assignee, msg.sender);
  }

  function resolveDisputeSeller(string uid) onlyAssignee(uid) {
    disputeInterface.resolveDisputeSeller(uid, disputes[uid].ethOrderBook);
    DisputeResolved(disputes[uid].ethOrderBook, uid, 'seller', msg.sender);
  }

  function resolveDisputeSeller(string uid, address ethOrderBookAddress) onlyAssignee(uid) {
    disputeInterface.resolveDisputeSeller(uid, ethOrderBookAddress);
    DisputeResolved(ethOrderBookAddress, uid, 'seller', msg.sender);
  }

  function resolveDisputeBuyer(string uid) onlyAssignee(uid) {
    disputeInterface.resolveDisputeBuyer(uid, disputes[uid].ethOrderBook);
    DisputeResolved(disputes[uid].ethOrderBook, uid, 'buyer', msg.sender);
  }

  modifier onlyAssignee(string uid) {
    if(disputes[uid].assignee != msg.sender && !isOwner(msg.sender))
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
