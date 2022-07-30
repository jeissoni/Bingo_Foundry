// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import {console} from "forge-std/console.sol";
import "forge-std/Test.sol";
import "../src/Bingo.sol";
import "../src/chainlink/VRFv2Consumer.sol";

interface CheatCodes {
    function addr(uint256) external returns (address);
}

contract BingoTest is Test {
    
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    Bingo private testBingo;
    address private owner;
    address private addr1;   
                                   
    address private USDT = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);                                        
    address private AddressAdminVRF = address(0x66F3794178997a12779527B36a2F042e001625aF);

    uint64 constant private subscriptionId = 259;

    enum words {
        B,
        I,
        N,
        G,
        O
    }

   
    function setUp() public {
        owner = msg.sender;
        addr1 = cheats.addr(1);
        testBingo = new Bingo(USDT, subscriptionId);
    }

    function testExample() public {
      //console.log(testBingo.wordstest());
       
    }


    function testCreatePlay() public {

        uint256 maxNumberCartonsInit = 50;
        uint256 numberPlayerInit = 10;
        uint256 cartonByPlayer = 5;
        uint256 priceCartons = 10e6;
        uint256 endDate = block.timestamp + 1 days;

        testBingo.createPlay(
            maxNumberCartonsInit,
            numberPlayerInit,
            cartonByPlayer,
            priceCartons,
            endDate);        
       

        ( uint256 idPlay,
        uint256 maxNumberCartons,
        uint256 cartonsSold,
        uint256 numberPlayer,    
        uint256 cartonsByPlayer,
        uint256 cartonPrice,
        uint256 startPlayDate,
        uint256 endPlayDate,
        uint256 amountUSDT,
        address ownerPlay,)= testBingo.play(1);

        assertEq(maxNumberCartonsInit, maxNumberCartons);
        assertEq(0, cartonsSold);
        assertEq(numberPlayerInit, numberPlayer);
        assertEq(cartonByPlayer, cartonsByPlayer);
        assertEq(priceCartons, cartonPrice);
        //assertEq(maxNumberCartonsInit, startPlayDate);
        assertEq(endDate, endPlayDate);
        assertEq(0, amountUSDT);
        assertEq(maxNumberCartonsInit, ownerPlay);



        // uint256,
        // uint256,
        // uint256,
        // uint256,
        // uint256,
        // uint256,
        // uint256,
        // uint256,
        // uint256,
        // address,
        // enum Bingo.statePlay
    }
}


