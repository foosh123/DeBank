// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0;


contract RNG{
    uint256 fakeRandomNumber;

    function generateRandonNumber() public view returns (uint256){
        return fakeRandomNumber;
    }

    function setRandomNumber(uint256 forcedNumber) public{
         fakeRandomNumber = forcedNumber;
    }
}