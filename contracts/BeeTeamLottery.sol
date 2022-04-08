// "SPDX-License-Identifier: MIT"
// Smart contract Developed by BeeHive Team for Meter Hackathon
// Code by "kypanz" github : https://github.com/kypanz

pragma solidity ^0.8.0;

contract BeeTeamLottery {

    // Admin | options
    address beeTeamAdmin;
    uint256 minPercentageForRafflesWithdraw;
    bool securityBlockedStatus = false;
    string securityReason;

    constructor(){
        beeTeamAdmin = msg.sender;
        minPercentageForRafflesWithdraw = 80;
    }

    // Status of the Raffle
    enum statusRaffle { InProgress, Finished, Closed }

    // The Raffle
    struct Raffle{

        // Part one | Values returned in functions, see below
        address ownerOfRaffle;
        address winner;
        string nameOfRaffle;
        uint rewardAmount;
        bool statusRewarded;
        uint priceTicket;
        uint maxTickets;

        // Part two | Values returned in functions, see below
        statusRaffle status;
        uint256 counterTickets;
        uint256[] tickets;
        address[] participants;
        uint counterParticipants;
        uint256 initialDate;
        uint256 x_days;
    
    }

    // Users and tickets
    struct Tickets{
        uint256[] tickets; // todos mis tickets asociados a un raffle id
    }

    struct User{
        uint256[] myOwnRafflesId;
        uint256[] rafflesId;
        mapping(uint256 => Tickets) tickets;
        uint256 counterTickets;
    }

    // Mappings
    mapping(address => User) users;
    mapping(uint256 => Raffle) public raffles;

    // Modifiers
    modifier isBlocked(){
        require(securityBlockedStatus == false,'This function are blocked for security reasons');
        _;
    }
    modifier checkIfTheRaffleExist(uint256 _idRaffle){
        require(raffles[_idRaffle].ownerOfRaffle != 0x0000000000000000000000000000000000000000,'This raffle not exist');
        _;
    }
    modifier checkIfRaffleFinish(uint256 _idRaffle){
        // Check if the raffle finished in date time
        require(block.timestamp - raffles[_idRaffle].initialDate > ( raffles[_idRaffle].x_days * 1 days ) ,'This raffle are not in finish date');
        _;
    }
    modifier onlyAdmin() {
        require(msg.sender == beeTeamAdmin,'Only beeTeamAdmin can run this function');
        _;
    }
    modifier adminSecurity(){
        require(securityBlockedStatus == false,'This action is blocked for security reasons');
        _;
    }


    // TicketCounter
    uint256 raffleNumber = 1;

    // Users can create all Raffles that they want
    function createRaffle(string memory _nameRaffle, uint256 _rewardAmount, uint256 _priceTicket, uint256 _maxTickets, uint256 _days) isBlocked() public payable {
        
        require(msg.value > 0,'You need to send MTR');
        require( (_rewardAmount * 10 ** 18) == msg.value - ( 2 * 10 ** 18 ), 'send the same MTR at rewardAmount + 2 MTR more');
        require(_days >= 1,'Minimun Day 1 , Maximun day 7');
        require(_priceTicket >= 1,'Minimun price ticket 1 MTR');
        require(_maxTickets >= 10,'Minimun tickets to sell - 10');

        // Setting the data for the raffle
        raffles[raffleNumber].ownerOfRaffle = msg.sender;
        raffles[raffleNumber].nameOfRaffle = _nameRaffle;
        raffles[raffleNumber].rewardAmount = _rewardAmount;
        raffles[raffleNumber].priceTicket = _priceTicket;
        raffles[raffleNumber].maxTickets = _maxTickets;
        raffles[raffleNumber].status = statusRaffle.InProgress;
        raffles[raffleNumber].counterTickets = 0;
        raffles[raffleNumber].initialDate = block.timestamp;
        raffles[raffleNumber].x_days = _days;

        // Setting the data for the user
        users[msg.sender].myOwnRafflesId.push(raffleNumber);

        // Adding the new raffle number
        raffleNumber++;

    }

    // Get information of some raffle here | You need to use the Part one and part Two functions to get all the data
    function getRaffleByIdPartOne(uint256 _id) public view returns(
        address ownerOfRaffle,
        address winner,
        string memory nameOfRaffle,
        uint rewardAmount,
        bool statusRewarded,
        uint priceTicket,
        uint maxTickets
        ) {
        return(
            raffles[_id].ownerOfRaffle,
            raffles[_id].winner,
            raffles[_id].nameOfRaffle,
            raffles[_id].rewardAmount,
            raffles[_id].statusRewarded,
            raffles[_id].priceTicket,
            raffles[_id].maxTickets
        );
    }

    function getRaffleByIdPartTwo(uint256 _id) public view returns(
        statusRaffle status,
        uint counterTickets,
        address[] memory _participants,
        uint256[] memory _tickets,
        uint256 initialDate,
        uint256 x_days
    ){
        return(
            raffles[_id].status,
            raffles[_id].counterTickets,
            raffles[_id].participants,
            raffles[_id].tickets,
            raffles[_id].initialDate,
            raffles[_id].x_days
        );
    }

    function getMyInfo() public view returns(uint256[] memory _myOwnRafflesId, uint256[] memory _myRafflesId, uint256[] memory _myTickets){
        _myOwnRafflesId = users[msg.sender].myOwnRafflesId;
        _myRafflesId = users[msg.sender].rafflesId;
        for(uint i = 0; i < users[msg.sender].rafflesId.length; i++){
            _myTickets = users[msg.sender].tickets[  uint256(users[msg.sender].rafflesId[i])  ].tickets;
        }
    }

    // Here you can buy a ticket for some tickets for specific raffle, anyone can buy exept the owner of the raffle
    // You can buy some many tickets that you want
    function buyTicket(uint256 _idRaffle) isBlocked() checkIfTheRaffleExist(_idRaffle) public payable {

        // Check if the raffle buy all the tickets
        require(raffles[_idRaffle].maxTickets != raffles[_idRaffle].counterTickets,'All tickets are selled');
        
        // You need to send the same MTR at the price per ticket
        require(msg.value == ( raffles[_idRaffle].priceTicket * 10 ** 18 ),'You need to send the price in MTR');

        // You cant buy tickets in your own raffle
        require(msg.sender != raffles[_idRaffle].ownerOfRaffle,'You cant buy tickets in your own raffle');

        // Adding the tickets
        raffles[_idRaffle].counterTickets++;

        // Adding the tickets and the participant
        raffles[_idRaffle].participants.push(msg.sender);
        raffles[_idRaffle].tickets.push( raffles[_idRaffle].counterTickets );

        // Adding the ticket and the raffle id to the user information
        users[msg.sender].rafflesId.push(_idRaffle);
        users[msg.sender].tickets[_idRaffle].tickets.push( raffles[_idRaffle].counterTickets );
    
    }

    // This function is runned for owner and participants
    function finishRaffle(uint256 _idRaffle) isBlocked() checkIfTheRaffleExist(_idRaffle) checkIfRaffleFinish(_idRaffle) public {

        require(raffles[_idRaffle].status == statusRaffle.InProgress,'This raffle are finished or closed');
        require(raffles[_idRaffle].ownerOfRaffle == msg.sender,'You need to be the owner of this raffle');
        require(raffles[_idRaffle].counterTickets > gettingTheMinimunTickets(raffles[_idRaffle].maxTickets),'You dont sell the minimun percentage of the raffle, you can close it');

        // Do the process to get the winner
        uint256 winnerTicket = random(raffles[_idRaffle].counterTickets);

        // Setting the winner
        raffles[_idRaffle].winner = raffles[_idRaffle].participants[winnerTicket];
        raffles[_idRaffle].status = statusRaffle.Finished;
        raffles[_idRaffle].statusRewarded = true;
        payable(address(raffles[_idRaffle].participants[winnerTicket])).transfer(raffles[_idRaffle].rewardAmount * 1 ether);

    }

    // Close the raffle
    function closeRaffle(uint256 _idRaffle) checkIfTheRaffleExist(_idRaffle) checkIfRaffleFinish(_idRaffle) public {
        require(raffles[_idRaffle].ownerOfRaffle == msg.sender,'You are not owner of this raffle');
        require(raffles[_idRaffle].status != statusRaffle.Closed,'You already close this raffle');
        raffles[_idRaffle].status = statusRaffle.Closed;
        payable(msg.sender).transfer(raffles[_idRaffle].rewardAmount);
    }

    // This functions can be used for participants if the owner of the raffle dont finish the raffle after 3 days more than expected finished date
    function getMyTicketPriceBack(uint256 _idRaffle, uint256 _ticketId) isBlocked()  public {

        require(raffles[_idRaffle].statusRewarded == false, 'This raffle are already rewarded, you cant get the ticket back');
        require(block.timestamp - raffles[_idRaffle].initialDate > ( raffles[_idRaffle].x_days + 3 * 1 days ) ,'You need to wait 3 days after finish date');

        // Logic for back ticket price to the participant
        bool iAmOwnerOfThatTicket = false;
        bool isDone = false;
        for(uint256 i =0; i< raffles[_idRaffle].tickets.length; i++){
            if(msg.sender == raffles[_idRaffle].participants[i] && _ticketId == raffles[_idRaffle].tickets[i]) {
                removeParticipantByIndex(_idRaffle,i);
                removeFromMyTickets(_idRaffle,_ticketId);
                iAmOwnerOfThatTicket = true;
                isDone = true;
            }
        }
        require(iAmOwnerOfThatTicket == true,'You are not owner of that ticket');

        // Decrease the ticket counter
        raffles[_idRaffle].counterTickets = raffles[_idRaffle].counterTickets - 1;

        // Refunding for the participant
        if(isDone == true) payable(address(msg.sender)).transfer(raffles[_idRaffle].priceTicket * 1 ether);

    }

    // Remove from my info
    function removeFromMyTickets(uint256 _idRaffle, uint256 _ticket) private {

       for(uint256 i =0; i < users[msg.sender].rafflesId.length; i++){
        
            if( _idRaffle == users[msg.sender].rafflesId[i] ){
                for(uint256 j =0; j < users[msg.sender].tickets[ users[msg.sender].rafflesId[i] ].tickets.length; j++ ){
                    if( _ticket == users[msg.sender].tickets[ users[msg.sender].rafflesId[i] ].tickets[j] ){
                        
                        // removing raffleid
                        users[msg.sender].rafflesId[i] = users[msg.sender].rafflesId[ users[msg.sender].rafflesId.length - 1 ];

                        // removing ticket
                        users[msg.sender].tickets[ users[msg.sender].rafflesId[i] ].tickets[j] = users[msg.sender].tickets[ users[msg.sender].rafflesId[i] ].tickets[ users[msg.sender].tickets[ users[msg.sender].rafflesId[i] ].tickets.length - 1 ];
                    
                        // done
                        users[msg.sender].tickets[ users[msg.sender].rafflesId[i] ].tickets.pop();
                        users[msg.sender].rafflesId.pop();
                        break;
                    }
                }
            }
       
       }
    }

    // Remove participant
    function removeParticipantByIndex(uint256 _raffleId,uint index) private {
        // Step one
        raffles[_raffleId].participants[index] = raffles[_raffleId].participants[ raffles[_raffleId].participants.length - 1 ];
        raffles[_raffleId].tickets[index] = raffles[_raffleId].tickets[ raffles[_raffleId].tickets.length - 1 ];
        // Step two
        raffles[_raffleId].participants.pop();
        raffles[_raffleId].tickets.pop();
    }

    // This function is used to get the right minimun percentage for withdraw
    function gettingTheMinimunTickets(uint256 _amount) private view returns(uint256) {
        return ( minPercentageForRafflesWithdraw * _amount ) / 100;
    }
    
    // Here are setting the minimun percentage
    function settingTheMinimunPercentage(uint256 _newPercentage) onlyAdmin() public {
        minPercentageForRafflesWithdraw = _newPercentage;
    }

    // Random Number
    function random(uint256 _number) private view returns(uint256){
        require(_number != 0,'You cant run a random number wihout participants');
        return uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty, msg.sender))) % _number;
    }

    // Blocking functions for security reason
    function blockFunctions(string memory _reason) onlyAdmin() public {
        (securityBlockedStatus == true) ? securityBlockedStatus = false : securityBlockedStatus = true;
        securityReason = _reason;
    }

    // Getting the reason of the block
    function statusOfBlockedFunctions() public view returns(bool, string memory){
        return(securityBlockedStatus,securityReason);
    }

    // Get the balance of this contract here | Status of Smart Contract Raffle - BeeHive Team
    function getSmartContractBalance() public view returns(uint256){
        return address(this).balance;
    }

}