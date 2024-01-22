// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {WETH9} from "../../src/WETH9.sol";
// import {StdCheats} from "forge-std/StdCheats.sol";
// import {CommonBase} from "forge-std/CommonBase.sol";
// import {StdUtils} from "forge-std/StdUtils.sol";
import {Test, console} from "forge-std/Test.sol";
import {LibAddressSet, AddressSet} from "../../src/LibAddressSet.sol";



contract Handler is Test{

    using LibAddressSet for AddressSet;

     AddressSet internal _actors;
     address internal currentActor;

    WETH9 public weth;
    uint256 public constant ETH_SUPPLY = 120_174_000;
    uint256 public ghost_depositSum;
    uint256 public ghost_withdrawSum;


    mapping (bytes32 => uint256) public calls;

    uint256 public ghost_zeroWithdrawals;

    constructor(WETH9 _weth){
        weth = _weth;
        vm.deal(address(this), ETH_SUPPLY);
    }



    modifier countCall(bytes32 key){
        calls[key]++;

        _;
    }

    modifier useActor(uint256 actorIndexSeed) {
        currentActor = _actors.rand(actorIndexSeed);

        _;
    }


    function callSummary() external view {
        console.log("Call summary:");
        console.log("-----------------------");
        console.log("deposit", calls["deposit"]);
        console.log("withdraw", calls["withdraw"]);
        console.log("sendFallback", calls["sendFallback"]);
        console.log("approve", calls["approve"]);
        console.log("transfer", calls["transfer"]);
        console.log("transferFrom", calls["transferFrom"]);
        console.log("------------------------------------");
        console.log("Zero withdrawals: ", ghost_zeroWithdrawals);
    }
   


    function deposit(uint256 amount) public createActor countCall("deposit") {
        amount  = bound(amount, 0 , address(this).balance);
        _pay(currentActor, amount);

        vm.prank(currentActor);
        weth.deposit{value: amount}();
        ghost_depositSum += amount;
    }

    function withdraw ( uint256 actorSeed, uint256 amount) public useActor(actorSeed) countCall("withdraw") {

        // address caller = _actors.rand(actorSeed);
        amount  = bound(amount, 0, weth.balanceOf(currentActor));
        if(amount == 0) ghost_zeroWithdrawals++;
        
        vm.startPrank(currentActor);
        weth.withdraw(amount);
        _pay(address(this), amount);
        vm.stopPrank();

        ghost_withdrawSum += amount;
    
    }

    function approve(uint256 actorSeed, uint256 spenderSeed,  uint256 amount) public useActor(actorSeed) countCall("approve") {
        address spender = _actors.rand(spenderSeed);

        vm.prank(currentActor);
        weth.approve(spender, amount);
    }


    function transfer(uint256 actorSeed, uint256 toSeed, uint256 amount) public useActor(actorSeed) countCall("transfer") {
        address to = _actors.rand(toSeed);

        amount = bound(amount, 0, weth.balanceOf(currentActor));

        vm.prank(currentActor);
        weth.transfer(to, amount);
    }


    function transferFrom(uint256 actorSeed, uint256 fromSeed, uint256 toSeed, uint256 amount, bool _approve) public useActor(actorSeed) countCall("transferFrom"){
        address from = _actors.rand(fromSeed);
        address to = _actors.rand(toSeed);

        amount = bound(amount, 0, weth.balanceOf(from));



        if(_approve){
            vm.prank(from);
            weth.approve(currentActor, amount);
        }else{
            amount = bound(amount, 0, weth.allowance(currentActor,  from));
        }

        vm.prank(currentActor);
        weth.transferFrom(from, to, amount);
    }


    receive() external payable{} 

    function sendFallback(uint256 amount) public  createActor countCall("sendFallback"){
        amount = bound(amount, 0, address(this).balance);
        _pay(currentActor, amount);

        vm.prank(currentActor);
        (bool success,) = address(weth).call{value: amount}("");
        require(success, "sendFallback failed");
        ghost_depositSum += amount;
    }

    function _pay(address to, uint256 amount) internal {
        (bool s,) =  to.call{value: amount}("");
        require(s, "pay() failed" );
    }


    function actors() external view  returns (address[] memory){
        return _actors.addrs;
    }

    // function forEachActor(function(address) external func) public {
    //     return _actors.forEach(func);
    // }

    function forEachActor(function(address) external func) public {
    _actors.forEach(func);
}


    function reduceActors(uint256 acc, function(uint256, address) external returns (uint256) func) public returns(uint256){
        return _actors.reduce(acc, func);
    }

    
    
    modifier createActor() {
        currentActor = msg.sender;
        _actors.add(msg.sender);

        _;
    }





}