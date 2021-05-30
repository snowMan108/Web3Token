// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract RuinChamber is ERC721, Ownable {
    using Counters for Counters.Counter;
    uint256 public maxSupply;
    mapping(uint => bytes32) public seeds;

    Counters.Counter private _tokenIdCounter;

    constructor(uint256 _maxSupply) ERC721("Ruin Chamber", "CHAMBER") {
        maxSupply = _maxSupply;
    }

    function safeMint(address to, string memory _chamberName) public onlyOwner {
        require(_tokenIdCounter._value < maxSupply, "Mint: Max supply has been reached.");
        require(validateName(_chamberName), "Mint: Invalid name.");
        _safeMint(to, _tokenIdCounter.current());
        seeds[_tokenIdCounter.current()] = keccak256(abi.encodePacked(_chamberName));
        _tokenIdCounter.increment();
    }

    function getSeed (uint _id) external view returns (uint){
        return uint(seeds[_id]);
    }

    function isFull() external view returns (bool){
        return (_tokenIdCounter._value == maxSupply);
    }

    /**
     * @dev Checks for alphanumeric characters only and length between 1-25 characters.
     */
    function validateName (string memory _name) public pure returns (bool) {
        bytes memory nameBytes = bytes(_name);
        bool ret = nameBytes.length > 1 && nameBytes.length < 25;
        for (uint i; i < nameBytes.length; i++){
            bytes1 char = nameBytes[i];
            ret = ret &&
            ((char >= 0x61 && char <= 0x7A) || //a-z
            (char >= 0x41 && char <= 0x5A) || //A-Z
            (char >= 0x30 && char <= 0x39) || //9-0
            (char == 0x20)); //Whitespace;
        }
        return ret;
    }
}