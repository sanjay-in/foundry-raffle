// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

/**
 * @title Lottery smart contract
 * @author Sanjay
 * @notice This smart contract picks up random winner and sends them ETH after a specified time automatically
 */
contract Raffle is VRFConsumerBaseV2 {
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /* State variables */
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    uint256 private immutable i_timeInterval;
    uint256 private s_lastTimestamp;
    VRFCoordinatorV2Interface private immutable i_coordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_keyHash;
    uint32 private i_callbackGasLimit;
    address private s_recentWinner;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    RaffleState private s_raffleState;

    /* Events */
    event Players(address indexed players);
    event WinnerSelected(address indexed winner);

    /* Errors */
    error Raffle__NotEnoughEth();
    error Raffle__NotEnoughTimePassed();
    error Raffle__TransferFailed();
    error Raffle__StateNotOpen();

    constructor(
        uint256 entranceFee,
        uint256 timeInterval,
        address vrfCoordinator,
        uint64 subscriptionId,
        bytes32 keyHash,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_timeInterval = timeInterval;
        s_lastTimestamp = block.timestamp;
        i_coordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEth();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__StateNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit Players(msg.sender);
    }

    function pickWinner() external {
        if ((block.timestamp - s_lastTimestamp) <= i_timeInterval) {
            revert Raffle__NotEnoughTimePassed();
        }
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_coordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 randomNumber = randomWords[0] % s_players.length;
        address payable winner = s_players[randomNumber];
        s_recentWinner = winner;
        emit WinnerSelected(winner);

        // reseting lottery
        s_players = new address payable[](0);
        s_lastTimestamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;

        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /** Getter functions */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
