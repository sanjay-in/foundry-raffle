// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Lottery smart contract
 * @author Sanjay
 * @notice This smart contract picks up random winner and sends them ETH after a specified time automatically
 */
contract Raffle {
    uint256 private immutable i_entranceFee;

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enterRaffle() public payable {}

    function pickWinner() public {}
}
