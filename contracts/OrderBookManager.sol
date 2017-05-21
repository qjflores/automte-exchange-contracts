pragma solidity ^0.4.11;

import "./zeppelin/MultisigWallet.sol";

contract OrderBookManager is MultisigWallet {


  function OrderBookManager(address [] _owners, uint _required, uint _daylimit)
  MultisigWallet(_owners, _required, _daylimit) payable {
  }

  //need to include this to inherit multisig
  function changeOwner(address _from, address _to) external { }

}
