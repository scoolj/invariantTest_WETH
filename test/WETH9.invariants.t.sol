// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {WETH9}  from "../src/WETH9.sol";
import {Handler} from "./handlers/Handler.sol";

contract WETH9Invariants is Test {
    WETH9 public weth;
    Handler public handler;

    function setUp() public {
        weth = new WETH9();
        handler = new Handler(weth);

        bytes4[] memory selectors = new bytes4[](6);
        selectors[0] = Handler.deposit.selector;
        selectors[1] =  Handler.withdraw.selector;
        selectors[2] =  Handler.sendFallback.selector;
        selectors[3] = Handler.approve.selector;
        selectors[4] = Handler.transfer.selector;
        selectors[5] = Handler.transferFrom.selector;

 

        targetSelector(
            FuzzSelector({
            addr: address(handler),
            selectors : selectors
        }));

        
        targetContract(address(handler));

    }


    // function invariant_badInvariantThisShouldFail() public {
    //     assertEq(0, weth.totalSupply());
    // }

    // function invariant_wethSupplyIsAlwaysZero() public {
    //     assertEq(0, weth.totalSupply());
    // }

    // function test_zeroDeposit() public {
    //     weth.deposit{value: 0}();
    //     assertEq(0, weth.balanceOf(address(this)));
    //     assertEq(0, weth.totalSupply());
    // }


    function invariant_conservationOfEth() public {

        assertEq(
            handler.ETH_SUPPLY(), 
            address(handler).balance + weth.totalSupply()
            );
        
 
    }

    function invariant_solvencyDeposits() public {
        assertEq(address(weth).balance, handler.ghost_depositSum() - handler.ghost_withdrawSum());
    }

    // function invariant_solvencyBalances() public {
    //     uint256 sumOfBalances;

    //     address[] memory actors = handler.actors();

    //     for (uint256 i;  i< actors.length; ++i){
    //         sumOfBalances += weth.balanceOf(actors[i]);
    //     }


    //     assertEq(address(weth).balance, sumOfBalances);
    // }

    function invariant_solvencyBalances() public {
        uint256 sumOfBalances = handler.reduceActors(0, this.accumulateBalance);

        assertEq(address(weth).balance, sumOfBalances);
    }

    function accumulateBalance(uint256 balance, address caller) external view returns(uint256){
        return balance + weth.balanceOf(caller);
    }


    function invariant_depositorBalances() public {
        handler.forEachActor(this.assertAccountBalanceLteTotalSupply);
    }


    function assertAccountBalanceLteTotalSupply(address account) external {
        assertLe(weth.balanceOf(account),  weth.totalSupply());
    }

    function invariant_callSummary() public view {
        handler.callSummary();
    }





}