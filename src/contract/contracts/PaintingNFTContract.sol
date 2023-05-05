// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PaintingNFTContract is ERC721("DAppFi", "DAPP"), Ownable {
    struct Painting {
        uint256 tokenId;
        address payable owner;
        uint256 price;
        string URI;
    }

    event BoughtEvent(
        uint256 indexed tokenID,
        address indexed seller,
        address buyer,
        uint256 price
    );

    event ListedEvent(
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price
    );
    event CancelListedEvent(
        uint256 indexed tokenId
    );

    address public operator;
    Painting[] public paintings;
    uint256 public tax;
    
    constructor(address _operator, uint256 _tax) {
        operator = _operator;
        tax = _tax;
    }

    function createNFT(string memory _tokenURI) external{
        uint256 tokenId = paintings.length;
        _mint(msg.sender, tokenId);
        paintings.push(Painting(tokenId, payable(msg.sender), 0, _tokenURI));
    }

    function listNFT(uint256 _tokenId, uint256 _price) external payable {
        require (
            _price > 0,
            "List Failed: invalid price (price must be greater than 0)"  
        );
        paintings[_tokenId].price = _price;
        _transfer(msg.sender, address(this), _tokenId);
        emit ListedEvent(_tokenId, msg.sender, _price);
    }

    function cancelListNFT(uint256 _tokenId) external payable {
        address owner = paintings[_tokenId].owner;
        require(
            msg.sender == owner,
            "Cancel listed NFT Failed: It is NOT your NFT"  
        );
        _transfer(address(this), msg.sender, _tokenId);
        emit CancelListedEvent(_tokenId);
    }

    function buyNFT(uint256 _tokenId) external payable {
        uint256 price = paintings[_tokenId].price;
        address owner = paintings[_tokenId].owner;
        require(
            msg.value == price + tax,
            "Payment Failed: incorret ETH quantity"
        );
        paintings[_tokenId].owner = payable(msg.sender);
        _transfer(address(this), msg.sender, _tokenId);
        payable(operator).transfer(tax);
        payable(owner).transfer(price);
        emit BoughtEvent(_tokenId, owner, msg.sender, price);
    }

    function getUnsoldNFT() external view returns (Painting[] memory) {
        uint256 num = balanceOf(address(this));
        Painting[] memory NFTs = new Painting[](num);
        uint256 index = 0;
        for (uint256 i = 0; i < paintings.length; i++) {
            if (ownerOf(i) == address(this)) {
                NFTs[index] = paintings[i];
                index++; 
            }
        }
        return NFTs;
    }

    function getMyNFT() external view returns (Painting[] memory) {
        uint256 num = 0;
        for (uint256 i = 0; i < paintings.length; i++) {
            if (paintings[i].owner == msg.sender) {
                num++;
            }
        }
        uint256 index = 0;
        Painting[] memory NFTs = new Painting[](num);
        for (uint256 i = 0; i < paintings.length; i++) {
            if (paintings[i].owner == msg.sender) {
                NFTs[index] = paintings[i];
            }
        }
        return NFTs;
    }
}