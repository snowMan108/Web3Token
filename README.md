		# SunkenTemple
Web3 Weekend May 2021

This project is a board game idea and also my first solidity contract. The theme of the game is treasure hunting and exploration in a sunken city under the sea.
I decided to design a game using unchecked math to emulate a map grid with infinite wrapping. 
# Rules:
1. The board consists of 256 different spaces. At the beginning of the game, the starting position is decided and four statues are spawned in pseudo-random positions.
2. The first player deposits eth to claim the throne.
3. Players can then bid 5% or more of the last price to dethrone the previous player. To do so, they need to "explore" a space adjacent to the current position or, if all the adjacent positions are taken (dead end), a position adjacent to any previously explored case. 
4. If a player finds a statue in the newly claimed space, they gain 25% of the current treasury. 
5. When a player is dethroned, they recover 90% of what they paid. The other 10% is sent to the treasury.
6. When all 256 spaces are explored, the game ends and the last player to claim wins half the treasury. The other half is divided among all the other players proportional to the number of spaces claimed.
7. The player holding the throne is also able to claim 1% of the treasury every 24 hours, but by doing so they also reduce the entry fee by 1%. 

The game is designed to use the quirks of solidity/blockchain as mechanics. Predictable randomness helps people strategize and even promotes teamwork to beat the game. Finding the statues early in the game is less profitable, so a strategy would be to trick someone else into triggering a dead end so that another player could more freely pick a space. Unlike other hot-potato games, claiming more spaces is rewarding and benefits everyone else. 

The chamber contract is an ERC-721 that gets minted in the player's name whenever they claim a space. 
When doing so, the player chooses a name for the chamber and this is turned into a seed. 
This seed will be placed into a formula inside substance designer to create unique patterns and textures for each room.
The whole map is stored inside a uint256 with bit-wise flags to represent whether a space is occupied or not. There are also custom math functions to make the map wrap around infinitely like a globe, allowing the exploration in all four directions. I also used unchecked math to make uint256 arithmetic overflow and wrap around. The contract keeps count of each player's balance throughout the whole game.
