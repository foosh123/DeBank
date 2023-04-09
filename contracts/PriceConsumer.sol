// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0;

contract PriceConsumer{
    uint8 price;

    function setPrice(uint8 forcedNumber) public{
         price = forcedNumber;
    }
    function getLatestPrice() public view returns (uint8) {
        return price;
    }
}