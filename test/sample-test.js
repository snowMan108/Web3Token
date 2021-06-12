const { expect } = require("chai");

describe("SunkenTemple", function(){
  let Temple;
  let templeToken;
  let owner, address1, address2, address3;

  beforeEach (async function () {
    Temple = await ethers.getContractFactory("SunkenTemple");
    [owner, address1, address2, ...address3] = await ethers.getSigners();
    templeToken = await Temple.deploy();
  });

  describe("Grid Init", function () {
    it("Should have a starting position in-bounds", async function () {
      expect(await templeToken.gridPosition()).to.be.within(0,255, "Out of bounds");
    });
  });

  describe("Move validation", function () {
    it("Should not allow moves that aren't adjacent", async function () {
      const position = await templeToken.gridPosition();
      await expect(templeToken.StealThrone(position+2, "New Name")).to.be.revertedWith('IllegalMove');
    });
  });

  describe("Holder Validation", function() {
    it("Should not allow the current holder to make a move", async function() {
      const position = await templeToken.gridPosition();
      await templeToken.StealThrone(position-1, "First Chamber", {value: 100});
      await expect(templeToken.StealThrone(position-1, "Third Chamber", {value : 300})).to.be.reverted;
    });
  });
  
  
});
