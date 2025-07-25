//SPDX-License-Identifier
pragma solidity ^0.8.20;

import {IERC20} from "../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";

abstract contract Parameters {
       address private immutable i_BASE_TOKEN;
       address private immutable i_TARGET_TOKEN;
}

contract AutoDCAInvestmentTool is Parameters{
       /**
        * @dev a struct that defines the dollar cost averaging plan for a user
        * @param baseToken is the stable coin that the user would invest
        * @param targetToken is the ERC20 that the uniswap router would swap for the user
        * @param interval is the time interval in which the investments will be automated in 
        * @param amountPerSwap is the amount of stable coins which each user would like to invest on each interval
        * @param lastExecution is the time of total investments of the investment plan ? update lastExecution
        * @param remainingBalance ? reduce remainingBalance
        */

       struct DCAPlan {
              uint256 interval; 
              uint256 amountPerSwap;
              uint256 lastExecution;
              uint256 remainingBalance; 
       }

       mapping (address => DCAPlan) userPlan;

       function createPlan(
              uint256 _interval,
              uint256 _amountPerSwap,
              uint256 _lastExecution) 
              external returns (DCAPlan memory newPlan) {
                     require(_interval>0 && _interval< 4 weeks);
                     require(_amountPerSwap>0, "must invest coins");
                     require(_lastExecution>0, "atleast 1 investment");

                     userPlan[msg.sender] = newPlan;

                     
              }
}