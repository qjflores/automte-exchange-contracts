pragma solidity ^0.4.11;

import "./ETHOrderBook.sol";

contract ETHOrderBookMock is ETHOrderBook {

  function ETHOrderBookMock(address _seller, address _disputeResolver, string _country, uint _feePercent, uint min, uint max)
    ETHOrderBook(_seller, _disputeResolver, _country, _feePercent, min, max)
  {

  }

  function checkDispute(string uid) onlyDisputeResolver statusIs(uid, OrderBook.Status.Open) {
    orderBook.orders[uid].status = OrderBook.Status.Disputed;
  }

}
