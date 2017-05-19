pragma solidity ^0.4.11;

import "./OrderBookFactory.sol";
import "./zeppelin/MultisigWallet.sol";

contract OrderBookManager is MultisigWallet {

  OrderBookFactory public factory;

  function OrderBookManager(address [] _owners, uint _required, uint _daylimit)
  MultisigWallet(_owners, _required, _daylimit) payable {
    factory = new OrderBookFactory();
  }

  //need to include this to inherit multisig
  function changeOwner(address _from, address _to) external { }

}
