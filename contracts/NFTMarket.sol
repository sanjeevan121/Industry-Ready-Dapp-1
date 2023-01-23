// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

contract NFTMarketplace is ERC721URIStorage,ReentrancyGuard,Ownable{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;

    uint256 listingPrice=0.001 ether;
    address payable owner;
    
    mapping(uint256=>Marketitem) private idToMarketItem;

    struct Marketitem{
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    event MarketItemCreated(
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    
    constructor() ERC721("Ineuron Tokens","INT"){
        owner=payable(msg.sender);
    }

    function updateListingPrice(uint256 _listingPrice) public payable onlyOwner{
        listingPrice=_listingPrice;
    }

    function getListingPrice() public view returns(uint256){
        return listingPrice; 
    }
     
    function createToken(string memory tokenURI,uint256 price) public payable returns(uint256){
        _tokenIds.increment();
       uint256 newItemId=_tokenIds.current();

        //mint new tokens, with msg.send as the creator and item id as the item id
        //The _mint() internal function is used to mint a new NFT at the given address.
        // As the function is internal, it can only be used from inherited contracts to mint 
        //new tokens. This function takes the following arguments:

        //to: The address of the owner for whom the new NFT is minted
        //tokenId: The new tokenId for the token that will be minted

        //When you deploy the contract msg.sender is the owner of the contract. 
        //If you have a variable defined in your contract by the name of "owner",
        // you can assign it with the value(address) of msg.sender.

       _mint(msg.sender,newItemId); 
       _setTokenURI(newItemId,tokenURI);

       //gives the marketplace the permission to transact this token between 
       // users from any external contract
       createMarketItem(newItemId,price);
     //  setApprovalForAll(contractAddress,true);
       return newItemId;
    }

    function createMarketItem(uint256 tokenId,uint256 price) public payable nonReentrant{
        require(price>0,"price must be at least 1 wei");
        require(msg.value==listingPrice,"price must be equal to listing price");

        idToMarketItem[tokenId]=Marketitem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );
        _transfer(msg.sender,address(this),tokenId);
   
        emit MarketItemCreated(
            tokenId, 
            msg.sender, 
            address(this), 
            price, 
            false);
    }

    function reSellToken(uint256 tokenId,uint256 price) public payable{
        require(idToMarketItem[tokenId].owner==msg.sender,"only NFT owner can perform this operation");
        require(msg.value==listingPrice,"price must be equal to the listing price");

        idToMarketItem[tokenId].sold=false;
        idToMarketItem[tokenId].price=price;
        idToMarketItem[tokenId].seller=payable(msg.sender);
        idToMarketItem[tokenId].owner=payable(address(this));

        _itemsSold.decrement();
        _transfer(msg.sender,address(this),tokenId);
    }

    function createMarketSale(uint256 tokenId) public payable nonReentrant{
        uint256 price=idToMarketItem[tokenId].price;
        require(msg.value==price,"Price should be equal to asking price for the NFT");

        idToMarketItem[tokenId].owner=payable(msg.sender);
        idToMarketItem[tokenId].sold=true;
        idToMarketItem[tokenId].owner=payable(address(0));

        _itemsSold.increment();

        _transfer(address(this),msg.sender,tokenId);
        payable(owner).transfer(listingPrice);
        payable(idToMarketItem[tokenId].seller).transfer(msg.value);
    }

    function fetchMarketItems() public view returns(Marketitem[] memory){
        uint256 itemCount=_tokenIds.current();
        uint unsoldItemCount= _tokenIds.current() - _itemsSold.current();
        uint currentIndex=0;

        Marketitem[] memory items = new Marketitem[](unsoldItemCount);
        for(uint i=0; i< itemCount;i++){
            if(idToMarketItem[i+1].owner==address(this)){
                uint256 currentId=i+1;
                Marketitem storage currentItem=idToMarketItem[currentId];
                items[currentIndex]=currentItem;
                currentIndex+=1;
            }

        }
            return items;
    }

    function fetchMyNFTs() public view returns (Marketitem[] memory){
        uint totalItemCount=_tokenIds.current();
        uint itemCount=0;
        uint currentIndex=0;

        for (uint i=0;i<totalItemCount;i++)
        {
            if(idToMarketItem[i+1].owner==msg.sender){
                itemCount+=1;   
                }
        }
            Marketitem[] memory items=new Marketitem[](itemCount);
            for(uint i=0;i<totalItemCount;i++)
            {
                if(idToMarketItem[i+1].owner==msg.sender){
                    uint currentId=i+1;
                    Marketitem storage currentItem = idToMarketItem[currentId];
                    items[currentIndex]=currentItem;
                    currentIndex+=1;
                }
            }
            return items;
    }

     function fetchItemsCreated() public view returns (Marketitem[] memory){

        uint totalItemCount = _tokenIds.current();
        uint itemCount=0;
        uint currentIndex=0;

        for (uint i=0 ; i<totalItemCount ; i++){
            if(idToMarketItem[i+1].seller==msg.sender){
                itemCount+=1;

            }
        }
        Marketitem[] memory items = new Marketitem[](itemCount);
        for(uint i=0;i< totalItemCount; i++){
            if(idToMarketItem[i+1].seller==msg.sender){
                uint currentId=i+1;
                Marketitem storage currentItem= idToMarketItem[currentId];
                items[currentIndex]=currentItem;
                currentIndex+=1;


            }
        }
        return items;
    }

}