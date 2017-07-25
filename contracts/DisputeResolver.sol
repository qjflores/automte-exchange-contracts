pragma solidity ^0.4.11;

import "./DisputeInterface.sol";
import "../oraclize-ethereum-api/oraclizeAPI_0.4.sol";

contract DisputeResolver is usingOraclize {

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

  struct DisputeAssignment {
    address assignee;
    address ethOrderBook;
  }

  mapping(string => DisputeAssignment) disputes;

  struct Dispute {
    address ethOrderBook;
    string uid;
  }

  mapping(bytes32 => Dispute) public disputeQueryIds;

  DisputeInterface disputeInterface;

  //note: sets msg.sender as owner
  function DisputeResolver(address[] _owners, address _disputeInterface) {
    owners[1] = msg.sender;
    ownerIndex[msg.sender] = 1;
    for (uint i = 0; i < _owners.length; ++i) {
      owners[2 + i] = _owners[i];
      ownerIndex[_owners[i]] = 2 + i;
    }

    disputeInterface = DisputeInterface(_disputeInterface);
  }

  function() payable {

  }

  event DisputeAssigned(address ethOrderBook, string uid, address assignee, address assigner);
  event DisputeEscalated(address ethOrderBook, string uid, address assignee, address assigner);
  event DisputeResolved(address ethOrderBook, string uid, string resolvedTo, address assignee);

  function assignDispute(string _uid, address _ethOrderBook, string country) onlyOwner {
    assignDispute(_uid, _ethOrderBook, country, msg.sender);
  }

  function assignDispute(string _uid, address _ethOrderBook, string country, address assignee) onlyOwner {
    bytes32 queryId = oraclize_query("URL", "json(https://us-central1-automteetherexchange.cloudfunctions.net/checkDispute).dispute", strConcat('\n{"country" :"', country, '", "orderId": "', _uid, '"}'));
    disputeQueryIds[queryId].uid = _uid;
    disputeQueryIds[queryId].ethOrderBook = _ethOrderBook;

    disputes[_uid].assignee = assignee;
    disputes[_uid].ethOrderBook = _ethOrderBook;
    DisputeAssigned(_ethOrderBook, _uid, assignee, msg.sender);
  }

  function __callback(bytes32 id, string result) {
    if(msg.sender != oraclize_cbAddress() || strCompare(disputeQueryIds[id].uid, "VOID") == 0) throw;
    if(strCompare(result, "true") == 0) {
      disputeInterface.setDisputed(disputeQueryIds[id].ethOrderBook, disputeQueryIds[id].uid);
    }
    disputeQueryIds[id].uid = "VOID";
  }

  function resolveDisputeSeller(string uid) onlyAssignee(uid) {
    disputeInterface.resolveDisputeSeller(uid, disputes[uid].ethOrderBook);
    DisputeResolved(disputes[uid].ethOrderBook, uid, 'seller', msg.sender);
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
