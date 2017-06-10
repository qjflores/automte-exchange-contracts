pragma solidity ^0.4.11;

import "./zeppelin/MultisigWallet.sol";
import "./Router.sol";

contract OrderBookManager is MultisigWallet {

  Router router;

  function OrderBookManager(address [] _owners, uint _required, uint _daylimit, address _router)
  MultisigWallet(_owners, _required, _daylimit) payable {
    router = Router(_router);
  }

  //need to include this to inherit multisig
  function changeOwner(address _from, address _to) external { }

  function changeRouterOwner(address newOwner) onlymanyowners(keccak256(msg.data)) {
    router.transferOwnership(newOwner);
  }

}
