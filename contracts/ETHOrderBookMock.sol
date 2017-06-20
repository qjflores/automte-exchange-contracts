pragma solidity ^0.4.11;

import "./ETHOrderBook.sol";

contract ETHOrderBookMock is ETHOrderBook {
  using SafeMath for uint;

  OrderBook.Orders orderBook;
  address public seller;
  string country;
  uint public availableBalance;
  uint feePercent; // 1 = 1% fee
  address disputeResolver;

  uint MINIMUM_ORDER_AMOUNT; //inclusive
  uint MAXIMUM_ORDER_AMOUNT; //exclusive

  mapping(bytes32 => string) disputeQueryIds;

  function ETHOrderBookMock(address _seller, address _disputeResolver, string _country, uint _feePercent, uint min, uint max)
    ETHOrderBook(_seller, _disputeResolver, _country, _feePercent, min, max)
  {

  }

  function checkDispute(string uid) onlyDisputeResolver statusIs(uid, OrderBook.Status.Open) {
    orderBook.orders[uid].status = OrderBook.Status.Disputed;
  }

}
