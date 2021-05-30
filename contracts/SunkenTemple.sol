// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Chamber.sol";

contract SunkenTemple is Ownable{
    using SafeMath for uint256;
    
    uint256 public throneFee;
    uint256 public treasury;
    uint256 gridMap;
    uint8 public gridPosition;
    RuinChamber public chamber;
    address payable public throneHolder;
    uint256 public lockedThroneFee;
    mapping (address => uint256) balances;
    uint8[4] private statues;
    
    event Explore(address addr, string chamberName, uint256 amountPaid);
    event TreasureFound(address addr, uint8 position);
    
    constructor() {
        chamber = new RuinChamber(256);
        statues[0] = uint8(uint(keccak256(abi.encodePacked(block.difficulty+1, block.timestamp))) % 256);
        statues[1] = uint8(uint(keccak256(abi.encodePacked(block.difficulty+2, block.timestamp))) % 256);
        statues[2] = uint8(uint(keccak256(abi.encodePacked(block.difficulty+3, block.timestamp))) % 256);
        statues[3] = uint8(uint(keccak256(abi.encodePacked(block.difficulty+4, block.timestamp))) % 256);
        gridPosition = uint8(uint(keccak256(abi.encodePacked("Good luck", block.timestamp))) % 256);
    }
    
    function StealThrone(uint8 _newPos, string memory _roomName) external payable{
        require(msg.sender != throneHolder && msg.value >= minPrice(throneFee));
        require(ValidateMovement(_newPos), "IllegalMove");
        require(!chamber.isFull(), "GameOver");
        balances[throneHolder] += lockedThroneFee; // Give back the locked fee to the old holder
        uint256 priceDelta = msg.value - throneFee;
        uint256 amount = priceDelta / 10;
        amount = amount == 0 ? 1 : amount; // Round up to 1 if it's 0
        treasury += amount; // 10% of the difference in price goes to the treasury
        lockedThroneFee = priceDelta - amount; // The rest gets locked
        throneFee = msg.value;
        throneHolder = payable(msg.sender);
        gridMap = occupySpace(gridMap, uint256(_newPos));
        gridPosition = _newPos;
        chamber.safeMint(msg.sender, _roomName); // Mint the chamber and give ownership to new throne holder
        CheckForTreasure(_newPos);
        if(chamber.isFull()){
            GameOver(msg.sender);
        }
        emit Explore(msg.sender, _roomName, msg.value);
    }

    function GameOver(address winner) private {
        treasury.add(lockedThroneFee);
        lockedThroneFee = 0;
        uint256 half = treasury / 2;
        balances[winner] = treasury - half;
        treasury = half;
        uint256 amount = treasury / chamber.maxSupply();
        for(uint i = 0; i < chamber.maxSupply(); i++){
            balances[chamber.ownerOf(i)].add(amount);
            treasury.sub(amount);
        }
        balances[winner].add(treasury);
        treasury = 0;
    }
    
    function CheckForTreasure(uint8 _pos) private {
        for(uint i = 0; i < statues.length; i++){
            if(_pos == statues[i]){
                uint256 amount = treasury/4;
                treasury.sub(amount);
                balances[throneHolder].add(amount);
                emit TreasureFound(throneHolder, _pos);
            }
        }
    }

    function Withdraw() public returns (bool) {
        uint256 amount = balances[msg.sender];
        if (amount > 0) {
            balances[msg.sender] = 0;
            if (!payable(msg.sender).send(amount)){
                balances[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }
    
    function CheckBalance(address _address) external view returns (uint256){
        return balances[_address];
    }
    
    function ValidateMovement(uint8 _newPos) private view returns (bool){
        uint8 pos = gridPosition;
        uint8 map = uint8(gridMap);
        if(isOccupied(gridMap, _newPos)) {
            return false;
        }
        //Check if all adjacent to current position are taken first
        if (isDeadEnd(map, pos)) {
            return hasAdjacent(map, _newPos);
        } else {
            return isAdjacentTo(pos, _newPos);
        }
    }

    enum Direction {
        North, Northeast, East, Southeast,
        South, SouthWest, West, Northwest
    }

    function isDeadEnd(uint256 _gridMap, uint8 _currentPos) internal pure returns (bool){
        return isOccupied(_gridMap, moveTo(_currentPos, Direction.North)) &&
        isOccupied(_gridMap, moveTo(_currentPos, Direction.Northeast)) &&
        isOccupied(_gridMap, moveTo(_currentPos, Direction.East)) &&
        isOccupied(_gridMap, moveTo(_currentPos, Direction.Southeast)) &&
        isOccupied(_gridMap, moveTo(_currentPos, Direction.South)) &&
        isOccupied(_gridMap, moveTo(_currentPos, Direction.SouthWest)) &&
        isOccupied(_gridMap, moveTo(_currentPos, Direction.West)) &&
        isOccupied(_gridMap, moveTo(_currentPos, Direction.Northwest));
    }
    /**
    * @dev Checks whether the new position has any flags set to true next to it.
    */
    function hasAdjacent(uint256 _gridMap, uint8 _newPos) internal pure returns (bool) {
        return isOccupied(_gridMap, moveTo(_newPos, Direction.North)) ||
        isOccupied(_gridMap, moveTo(_newPos, Direction.Northeast)) ||
        isOccupied(_gridMap, moveTo(_newPos, Direction.East)) ||
        isOccupied(_gridMap, moveTo(_newPos, Direction.Southeast)) ||
        isOccupied(_gridMap, moveTo(_newPos, Direction.South)) ||
        isOccupied(_gridMap, moveTo(_newPos, Direction.SouthWest)) ||
        isOccupied(_gridMap, moveTo(_newPos, Direction.West)) ||
        isOccupied(_gridMap, moveTo(_newPos, Direction.Northwest));
    }

    /**
    * @dev Checks whether two positions are next to each other.
    */
    function isAdjacentTo(uint8 _a, uint8 _b) internal pure returns (bool) {
        return moveTo(_a, Direction.North) == _b ||
        moveTo(_a, Direction.Northeast) == _b ||
        moveTo(_a, Direction.East) == _b ||
        moveTo(_a, Direction.Southeast) == _b ||
        moveTo(_a, Direction.South) == _b ||
        moveTo(_a, Direction.SouthWest) == _b ||
        moveTo(_a, Direction.West) == _b ||
        moveTo(_a, Direction.Northwest) == _b;
    }

    /**
    * @dev Checks if the flag is set for that position.
    */
    function isOccupied(uint256 _gridMap, uint256 _pos) internal pure returns (bool){
        uint256 flag = (_gridMap >> _pos) & uint256(1);
        return (flag == 1 ? true : false);
    }

    /**
    * @dev Sets the flag for the position in the grid.
    */
    function occupySpace (uint256 _gridMap, uint256 _pos) internal pure returns (uint256){
        return _gridMap | uint256(1) << _pos;
    }

    /**
    * @dev Returns the position in that direction with wrapping.
    */
    function moveTo(uint8 pos, Direction direction) internal pure returns (uint8) {
        unchecked {
        if (direction == Direction.North) return pos-16;
        if (direction == Direction.Northeast){
            // Edge Wrap-Around Math
            if (pos % 16 == 15) {
                return pos-31;
            }
            return pos-15;
        }
        if (direction == Direction.East) {
            if ( pos % 16 == 15){
                return pos-15;
            }
            return pos+1;
        }
        if (direction == Direction.Southeast) {
            if (pos % 16 == 15){
                return pos + 1;
            }
            return pos+17;
        }
        if (direction == Direction.South) return pos+16;
        if (direction == Direction.SouthWest) {
            if (pos % 16 == 0){
                return pos+31;
            }
            return pos+15;
        }
        if (direction == Direction.West) {
            if (pos % 16 == 0) {
                return pos+15;
            }
            return pos-1;
        }
        if (direction == Direction.Northwest){
            if (pos % 16 == 0) {
                return pos-1;
            }
            return pos-17;
        }
        return pos;
        }
    }

    /**
    * @dev Calculates the throne fee based on a 5% increase.
    */
    function minPrice(uint256 _basePrice) private pure returns (uint){
        return _basePrice + _basePrice/20;
    }
    
    function contractBalance() external view returns (uint){
        return address(this).balance;
    }

}
