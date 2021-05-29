// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Chamber.sol";

contract SunkenTemple is Ownable{
    using SafeMath for uint256;
    
    uint256 public throneFee;
    uint256 public treasury;
    uint8[16][16] public grid;
    RuinChamber public chamber;
    address payable public throneHolder;
    
    event Explore(address addr, string chamberName, uint256 amountPaid);
    
    constructor(uint256 _initialEntryFee) {
        throneFee = _initialEntryFee;
        chamber = new RuinChamber(256);
    }
    
    function StealThrone(uint8 direction, string memory roomName) external payable{
        require(msg.sender != throneHolder && msg.value >= minPrice(throneFee));
        require(ValidateDirection(direction));
        chamber.safeMint(msg.sender, roomName);
        throneFee = msg.value;
    }
    
    function ValidateDirection(uint8 direction) internal returns (bool){
        //TODO: Implement valid directions or spaces
        return true;
    }
    
    function minPrice(uint256 _basePrice) private pure returns (uint){
        return _basePrice + _basePrice.div(10);
    }

}
