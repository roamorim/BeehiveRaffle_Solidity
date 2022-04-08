// "SPDX-License-Identifier: MIT"
pragma solidity ^0.8.0;

contract Testing {    

    struct Tickets{
        uint256[] tickets;
    }

    struct User{
        uint256[] rafflesId;
        uint256 counterMyRaffles;
        mapping(uint256 => Tickets) tickets;
    }

    mapping(address => User) users;

    function addTicket(uint256 _raffleId, uint256 _newValue) public { // buy ticket
        users[msg.sender].rafflesId.push(_raffleId);
        users[msg.sender].tickets[_raffleId].tickets.push(_newValue);
        users[msg.sender].counterMyRaffles++;
    }

    function getTickets(uint256 _raffleId) public view returns(uint256[] memory _rafflesId, uint256[] memory _ticketsId) {
    //function getTickets(uint256 _raffleId) public view returns(uint256[][] memory _rafflesId) {
        
        _rafflesId = users[msg.sender].rafflesId;
        for(uint i = 0; i < users[msg.sender].rafflesId.length; i++){
            _ticketsId = users[msg.sender].tickets[  uint256(users[msg.sender].rafflesId[i])  ].tickets;
        }

        
        /*
        // Preparing the data to retrive
        uint256[][] memory _tempData = new uint256[][](users[msg.sender].counterMyRaffles);

        // Setting the new data
        //for(uint i = 0; i < users[msg.sender].counterMyRaffles; i++){
        
        // The first for is used for getting the rafflesIds and the second is for the tickets of that raffle
        for(uint i = 0; i < users[msg.sender].rafflesId.length; i++){
            // For temp use, this is for take the two values key => value
            uint256[] memory _temp = new uint256[](2);

            // To Index
            uint256 _toIndex;
            uint256 _toIndexTickets;

            _toIndex = uint256(users[msg.sender].rafflesId[i]);
            _toIndexTickets = users[msg.sender].tickets[ _toIndex ].tickets.length;

            //_result = new uint256[2][](_toIndexTickets);
            for(uint256 j=0; j < _toIndexTickets;j++){
                // [keyvalue]
                _temp[0] = _toIndex;
                _temp[1] = users[msg.sender].tickets[ _toIndex ].tickets[j];
                _tempData[i] = _temp;
            }


        }
    
        return _tempData;
        */
    }

}