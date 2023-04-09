// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0;


contract RNG{
    uint8 fakeRandomNumber;

    function generateRandonNumber() public view returns (uint8){
        return fakeRandomNumber;
    }

    function setRandomNumber(uint8 forcedNumber) public{
         fakeRandomNumber = forcedNumber;
    }
}