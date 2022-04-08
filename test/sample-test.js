const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Testing Lottery/Raffle smrat contract for Behive Team", function () {

  // This variables are declared outside because is needed in all parts of the test
  let beeTeamContract;
  let owner;
  let addr1;
  let addr2;
  let addrs;


  beforeEach(async function () {

    // Accounts to testing
    [owner, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();

    // Initializating the contract
    const BeeTeamContract = await ethers.getContractFactory("BeeTeamLottery");
    beeTeamContract = await BeeTeamContract.deploy(); // number of Machines
    await beeTeamContract.deployed();

  });

  it("Deploy the contract", async function () {

  });

  it("Reverted if the creator not send the same MTR of reward amount",async () => {

    await expect(
      beeTeamContract.createRaffle("My First Raffle by BeeHive Team", 100, 5, 30,1)
    ).revertedWith('You need to send MTR');

    await expect(
      beeTeamContract.createRaffle(
        "My First Raffle by BeeHive Team", 20, 2, 30,1, {
          value: ethers.utils.parseEther("35.0")
      })
    ).to.be.revertedWith("send the same MTR at rewardAmount + 2 MTR more");
  
  });

  it("Register a Raffle",async () => {
    
    let resultCreateRaffle = await beeTeamContract.createRaffle(
      "My First Raffle by BeeHive Team", 20, 2, 30,1, {
        value: ethers.utils.parseEther("22.0")
    });

    await expect(
      resultCreateRaffle[0]
    ).to.be.not.equal('0x0000000000000000000000000000000000000000');

    describe("Getting Data of the smart contract", function() {

      beforeEach(async()=>{
        await beeTeamContract.createRaffle(
          "My First Raffle by BeeHive Team", 20, 2, 30, 1, {
            value: ethers.utils.parseEther("22.0")
        });
      })

      it("Checking Part1 and Part2 of the Raffle data",async() => {
        let resultOfFirstPartRaffle = await beeTeamContract.getRaffleByIdPartOne(1);
        await expect(
          resultOfFirstPartRaffle[2]
        ).to.be.equal("My First Raffle by BeeHive Team");
    
        let resultOfSecondPart = await beeTeamContract.getRaffleByIdPartTwo(1);
    
        await expect(
          resultOfSecondPart.status
        ).to.be.equal(0);
      });

      it("Checking if the creator has the Id of the Raffle in their user information",async()=>{
        let resultOfTheRaffleTicket = await beeTeamContract.getMyInfo();
        await expect(
          resultOfTheRaffleTicket._myOwnRafflesId.length
        ).to.be.above(0);
      });

      it("Checking the balance for the smart contract raffle",async() => {
        let resultBalanceContract = await beeTeamContract.getSmartContractBalance();
        expect(resultBalanceContract).to.be.above(0);
      });

    })


    describe("Buying Tickets", function(){
      
      it("Reverted if someone wants to buy in a raffle that not exist", async function () {

        await expect(
          beeTeamContract.connect(addr1).buyTicket(8)
        ).to.be.revertedWith("This raffle not exist");    
        
      });

      it("Reverts if somebody wants to try buy a ticket wihout paying the MTR price of that Raffle",async () => {

        // Success | This transaction send the same amount needed for the raffle
        await expect(
          beeTeamContract.connect(addr1).buyTicket(2)
        ).revertedWith('You need to send the price in MTR');

      });

      it("Can buy some tickets",async() => {
        await beeTeamContract.connect(addr1).buyTicket(2,{ value: ethers.utils.parseEther("2.0") });
        await beeTeamContract.connect(addr1).buyTicket(2,{ value: ethers.utils.parseEther("2.0") });
        await beeTeamContract.connect(addr1).buyTicket(2,{ value: ethers.utils.parseEther("2.0") });
        
        expect(
          ( await beeTeamContract.connect(addr1).getMyInfo() )[2].length
        ).to.be.equal(3);
      });

      it("Revert if someone wants to buy tickets when all tickets are selled",async() => {
        for(let i =0; i < 27; i++){
          await beeTeamContract.connect(addr1).buyTicket(2,{ value: ethers.utils.parseEther("2.0") });
        }
        await expect(
          beeTeamContract.connect(addr1).buyTicket(2,{ value: ethers.utils.parseEther("2.0") })
        ).revertedWith('All tickets are selled');
      });
    
    });

    describe("Finishing Raffle ( reward to the winner ) the Raffle",async() => {

      it("Reverted if the raffle dont finish yet",async() => {
        await beeTeamContract.createRaffle(
          "My First Raffle by BeeHive Team", 20, 2, 30, 1, {
            value: ethers.utils.parseEther("22.0")
        });

        await expect(
          beeTeamContract.finishRaffle(1)
        ).revertedWith('This raffle are not in finish date');

      });

      it("Revert error => You dont sell the minimun percentage of the raffle, you can close the raffle",async()=>{
        
        const days = 1 * 24 * 60 * 60;
        await ethers.provider.send('evm_increaseTime', [days]);
        await expect(
          beeTeamContract.finishRaffle(1)
        ).revertedWith('You dont sell the minimun percentage of the raffle, you can close it');

      });


      it("After 'X' days the owner of the raffle can finish ( user winner is rewarded ) | Revert if has winner too",async() => {

        // Setting the winner and sended the reward
        let myBalanceBefore = await ethers.provider.getBalance(addr1.address); // <-- for check the balance
        //console.log('Before : ',myBalanceBefore);

        await beeTeamContract.finishRaffle(2);

        // Rewarding the winnner
        await beeTeamContract.connect(addr1).getMyInfo();

        let myBalanceAfter = await ethers.provider.getBalance(addr1.address); // <-- for check the balance
        //console.log('After : ',myBalanceAfter);

        // Revert => has a winner
        await expect(
          beeTeamContract.finishRaffle(2)
        ).revertedWith('This raffle are finished or closed');

      });

      it("Participants can claim the raffle that not finishe after the expected date + 3 days more and then claim the reward",async() => {

        // Buying some tickets but not the 80%, with account 2
        for(let i =0; i < 5; i++){
          await beeTeamContract.connect(addr2).buyTicket(3,{ value: ethers.utils.parseEther("2.0") });
        }

        // Info of the raffle before remove elements
        //let raffleId = await beeTeamContract.getRaffleByIdPartOne(3);
        //let raffleId2 = await beeTeamContract.getRaffleByIdPartTwo(3);
        //console.log(raffleId,raffleId2);

        //let myInfo = await beeTeamContract.connect(addr2).getMyInfo();
        //console.log(myInfo);

        let myBalance = await ethers.provider.getBalance(addr2.address);
        //console.log(myBalance);
        
        await expect(
          beeTeamContract.connect(addr2).getMyTicketPriceBack(3,2)
        ).revertedWith('You need to wait 3 days after finish date');

        //console.log(resultOfRefund);

        const days = 3 * 24 * 60 * 60;
        await ethers.provider.send('evm_increaseTime', [days]);

        beeTeamContract.connect(addr2).getMyTicketPriceBack(3,2)

        // Info of the raffle after remove elements
        //let raffleIdx = await beeTeamContract.getRaffleByIdPartOne(3);
        //let raffleIdx2 = await beeTeamContract.getRaffleByIdPartTwo(3);
        //console.log(raffleIdx,raffleIdx2);


        let myInfox = await beeTeamContract.connect(addr2).getMyInfo();
        //console.log(myInfox);

        let myBalancex = await ethers.provider.getBalance(addr2.address);
        //console.log(myBalancex)


        // ------------------------------
        // Checking if are refunded right | ADDR3
        // ------------------------------
        await beeTeamContract.createRaffle(
          "Testing Refund", 20, 2, 30, 1, {
            value: ethers.utils.parseEther("22.0")
        });

        await beeTeamContract.connect(addr3).buyTicket(6,{ value: ethers.utils.parseEther("2.0") });
        
        // Checking the data of the raffle
        let raffleIdx = await beeTeamContract.getRaffleByIdPartOne(6);
        let raffleIdx2 = await beeTeamContract.getRaffleByIdPartTwo(6);
        //console.log(raffleIdx,raffleIdx2);

        // Before refund
        let myInfo = await beeTeamContract.connect(addr3).getMyInfo();
        //console.log(myInfo);

        // Get my balance Before the refund
        let b = await ethers.provider.getBalance(addr3.address);
        //console.log(b);

        // Advance 3 days
        const _days = 6 * 24 * 60 * 60;
        await ethers.provider.send('evm_increaseTime', [_days]);

        // Refund
        await beeTeamContract.connect(addr3).getMyTicketPriceBack(6,1)

        // Get my balance After refund
        let a = await ethers.provider.getBalance(addr3.address);
        //console.log(a);

        // After refund
        let myInfoAfter = await beeTeamContract.connect(addr3).getMyInfo();
        //console.log(myInfoAfter);

        let raffleIdxx = await beeTeamContract.getRaffleByIdPartOne(6);
        let raffleIdxx2 = await beeTeamContract.getRaffleByIdPartTwo(6);
        //console.log(raffleIdxx,raffleIdxx2);
      });

    });


    describe("Basic Security",async() => {

        it("Blocking functions for security reasons",async() =>{
          await beeTeamContract.blockFunctions('This are blocked for security the MTR of the users');
          await expect(
            beeTeamContract.createRaffle(
              "Testing Refund", 20, 2, 30, 1, {
                value: ethers.utils.parseEther("22.0")
            })
          ).revertedWith('This function are blocked for security reasons');
          //let reason = await beeTeamContract.statusOfBlockedFunctions();
          //console.log(reason);

        });

      });

  });

});
