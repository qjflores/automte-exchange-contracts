pragma solidity ^0.4.11;

import "./zeppelin/ownership/Ownable.sol";

contract Router is Ownable {

  function Router() {

  }

  function () payable {
    owner.transfer(msg.value);
  }

}
