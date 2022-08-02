// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import {console} from "forge-std/console.sol";
import "forge-std/Test.sol";
import "../src/Bingo.sol";
import "../src/Mock/USDT.sol";
import "../src/Mock/VRFCoordinatorV2Mock.sol";


interface CheatCodes {
    function addr(uint256) external returns (address);
}

contract BingoTest is Test {
    
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    VRFCoordinatorV2Mock public vRFCoordinatorV2Mock;
    
    USDT public Usdt;

    Bingo private testBingo;
    address private owner;
    address private addr1;  
    address private addr2;   
                                   
    //address private USDT = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);        
    address private USDTHolder = address(0x5671C525d378803e69e743E9cd22631cB371b77f);                                
 

    uint64 private subscriptionId;

    enum words {
        B,
        I,
        N,
        G,
        O
    }

    
    enum statePlay {
        CREATED,
        INITIATED,
        FINALIZED
    }

    words private letras;
    statePlay private states;
   
    function setUp() public {

        owner = msg.sender;
        addr1 = cheats.addr(1);
        addr2 = cheats.addr(2);


        Usdt = new USDT(100000);

        Usdt.transfer(addr1, 1000e6);

        vRFCoordinatorV2Mock = new VRFCoordinatorV2Mock(10**8, 10**8); //baseFee; gasPriceLink;
        subscriptionId = vRFCoordinatorV2Mock.createSubscription();
        vRFCoordinatorV2Mock.fundSubscription(subscriptionId, 10**23);

        testBingo = new Bingo(address(Usdt), subscriptionId, address(vRFCoordinatorV2Mock));
  
        vRFCoordinatorV2Mock.addConsumer(subscriptionId, address(testBingo));
    }

    function createNewPLay() public {
        uint256 maxNumCartonsInit = 50;
        uint256 numberPlayerInit = 10;
        uint256 cartonByPlayer = 5;
        uint256 priceCartons = 10e6;
        uint256 endDateInit = block.timestamp + 1 days;

        vm.prank(addr1);

        testBingo.createPlay(
            maxNumCartonsInit,
            numberPlayerInit,
            cartonByPlayer,
            priceCartons,
            endDateInit);         
    }


    function testCreatePlay() public {

        uint256 numberPlayerInit = 10;
        uint256 cartonByPlayer = 5;
        uint256 priceCartons = 10e6;
        uint256 startPlayInit = block.timestamp;
        uint256 endDateInit = block.timestamp + 1 days;

        createNewPLay();      

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

       
        assertEq(idPlay, 1);
        assertEq(maxNumberCartons, 50);
        assertEq(cartonsSold,0);
        assertEq(numberPlayerInit, numberPlayer);
        assertEq(cartonByPlayer, cartonsByPlayer);
        assertEq(priceCartons, cartonPrice);
        assertEq(endDateInit, endPlayDate);
        assertEq(amountUSDT,0);
        assertEq(ownerPlay, addr1);
        assertEq(startPlayInit, startPlayDate);
    }

    // function testInitPlay() public {
    //     createNewPLay();

    //     vm.prank(addr1);

    //     testBingo.changeStatePlayToInitiated(1);

    //     //Type tuple(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,address,enum Bingo.statePlay) is not implicitly convertible to expected type tuple(,,,,,,,,,,enum BingoTest.words).
    //     (,,,,,,,,,,statePlay otro) =testBingo.play(1);

    // }

    function testBuyCartonsPlay() public {
        createNewPLay();
    
        // vm.prank(AddressAdminVRF);
        // COORDINATOR.addConsumer(subscriptionId, address(testBingo));       

        (uint96 balance,
        uint64 reqCount,
        address owner,
        address[] memory consumers) = vRFCoordinatorV2Mock.getSubscription(1);
        
        vm.prank(addr1);
        bool isBuy = testBingo.buyCartonsPlay(1,1);
    }
}


