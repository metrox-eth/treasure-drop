// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";

contract TreasureDrop is ERC721A, Ownable {

    using Strings for uint256;

    mapping (address => uint256) private mintedWL;

    uint256 public maxSupply = 16;
    uint256 private pricePublic = 0.00 ether;
    uint256 public maxPerTxPublic = 1;
    uint256 public maxMintPerWallet = 1;

    bytes32 public merkleRoot = "";
    string private baseURI = "ipfs://QmUu3dwMQ6oG2Nti1T3G7ZnN1a6Pfhb8kMbtzq8hjVygAE/";
    string public uriNotRevealed = "ipfs://QmUu3dwMQ6oG2Nti1T3G7ZnN1a6Pfhb8kMbtzq8hjVygAE/";
    
    bool public paused = false;
    bool public isRevealed;

    mapping (bytes32 => uint) public authHashes;


    event Minted(address caller);
    event AuthHashChange(bytes32 hash, uint value);

    constructor() ERC721A("TreasureDrop", "TDR", maxPerTxPublic) {

    }
    
    function mintPublic(string memory key) external payable{
        require(!paused, "Minting is paused");
        
        uint256 supply = totalSupply();
        require(supply + 1 <= maxSupply, "Sorry, not enough left!");
        require(msg.value >= pricePublic * 1, "Sorry, not enough amount sent!"); 
        require(balanceOf(msg.sender) < maxMintPerWallet, "Sorry, too many per wallet");
        require(checkAutherized(key) > 0, "Sorry, you are not authorized!");
        
        _safeMint(msg.sender, 1);
        authHashes[keccak256(abi.encodePacked(key))] = 0;
        
        emit Minted(msg.sender);
        emit AuthHashChange(keccak256(abi.encodePacked(key)), 0);
    }
    
    function checkAutherized (string memory key) public view returns (uint){
        bytes32 keyHash = keccak256(abi.encodePacked(key));
        return authHashes[keyHash];
    }

    function remaining() public view returns(uint256){
        uint256 left = maxSupply - totalSupply();
        return left;
    }

    function getPricePublic() public view returns (uint256){
        return pricePublic;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (isRevealed == false) {
            return bytes(uriNotRevealed).length > 0 ? string(abi.encodePacked(uriNotRevealed, tokenId.toString(), ".json")) : "";
        }
        string memory base = baseURI;
        return bytes(base).length > 0 ? string(abi.encodePacked(base, tokenId.toString(), ".json")) : "";
    }

    // verify merkle tree leaf
    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool){
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }


    // ADMIN FUNCTIONS

    function setAuthHashes(uint256[] memory _hashes, uint[] memory values) public onlyOwner {
        for (uint i = 0; i < _hashes.length; i++) {
            authHashes[bytes32(_hashes[i])] = values[i];
            emit AuthHashChange(bytes32(_hashes[i]), values[i]);
        }
    }

    function flipPaused() public onlyOwner {
        paused = !paused;
    }
    
    function flipRevealed(string memory _URI) public onlyOwner {
        baseURI = _URI;
        isRevealed = !isRevealed;
    }

    function setBaseURI(string memory _URI) public onlyOwner {
        baseURI = _URI;
    }

    function setUriNotRevealed(string memory _URI) public onlyOwner {
        uriNotRevealed = _URI;
    }

    function setPricePublic(uint256 _newPrice) public onlyOwner {
        pricePublic = _newPrice;
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        maxSupply = _newMaxSupply;
    }


    // Set merkle tree root
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function withdraw(address payable _to) public onlyOwner {
        payable(_to).transfer(address(this).balance);
    }


    // helpers
    // list all the tokens ids of a wallet
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }
    
    receive() external payable {}
    
}