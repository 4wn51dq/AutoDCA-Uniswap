//SPDX-License-Identifier
pragma solidity ^0.8.20;

import {IERC20} from "../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {AutomationCompatibleInterface} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";

abstract contract Parameters {
       address internal immutable i_baseToken;
       address internal immutable i_targetToken;
       address internal immutable i_uniswapv2router;
       address internal immutable i_automationRegistryAddress; // the keeper node address
       uint256 internal constant PLAN_FEE = 1;
}

interface IDCAEvents {
       event PlanCreated(address indexed user, bytes32 planId);
       event DepositMade(address indexed user, uint256 amount);
       event SwapExecuted(address indexed user, uint256 amount, uint256 timestamp);
}

interface IUniswapV2RouterCustom {
       /**
        * @dev This function swaps exactly amountIn of tokenA for as many tokenB tokens as possible, 
        * with a minimum acceptable amount (amountOutMin) to protect against slippage.
        * note on slippage: @param amountOutMin is the minimum amount of target tokens you're willing to accept
        * this provides protection against slippage (slippage tolerance). Price can change from when you sign the 
        * transaction and to when it is mined, so you set the bar to avoid a bad deal.
        * @param path is not just of length 2 because there might be a case of multi-hop. 
        * note on multi-hop: no pool of [A,B], but there is a path [A,C] and [B,C], so path is [A, B, C].
        * @param deadline is the deadline for mining, if the transaction is not mined early, it shall revert.
        * amounts: amount of each token along the path. amounts[0] is amountIn and amounts[1] is amountOut.
        */
       function swapExactTokensForTokens(
              uint256 amountIn, // base tokens to be swapped
              uint256 amountOutMin, // minimum amount of target tokens you're willing to accept
              address[] calldata path,
              address to,
              uint256 deadline
       ) external returns (uint256[] memory amounts);

       // this function below 

       function getAmountsOut(
              uint256 amountIn,
              address[] calldata path
       ) external view returns (uint256[] memory amounts);

       // function WETH() external pure returns (address);
}

contract AutoDCAInvestmentTool is Parameters, IDCAEvents, AutomationCompatibleInterface{

       /**
        * @dev a struct that defines the dollar cost averaging plan for a user
        * @param i_baseToken is the stable coin that the user would invest
        * @param i_targetToken is the ERC20 that the uniswap router would swap for the user
        * @param interval is the time interval in which the investments will be automated in 
        * @param amountPerSwap is the amount of stable coins which each user would like to invest on each interval
        * @param swapsExecuted is the time of total investments of the investment plan ? update lastExecution
        * @param remainingBalance balance of the total deposits of the user in the plan ? reduce remainingBalance
        */

       struct DCAPlan {
              uint256 interval; 
              uint256 investmentPerSwap;
              uint256 swapsExecuted;
              uint256 remainingBalance; 
       }

       mapping (address => DCAPlan) userPlan;
       mapping (bytes32 => DCAPlan) planByPlanId;
       mapping (bytes32 => address) userOfPlan;
       mapping (address => uint256) userAssets;

       constructor (address stableCoin, address targetCoin, address router, address automator) {
              i_baseToken = stableCoin;
              i_targetToken = targetCoin;

              i_uniswapv2router = router;

              i_automationRegistryAddress = automator;
       }

       function createPlan(
              uint256 _interval,
              uint256 _investmentPerSwap) 
              external payable returns (DCAPlan memory newPlan) {
                     require(_interval>0 && _interval< 4 weeks);
                     require(_investmentPerSwap>0, "must invest coins");

                     /**
                      * one user can have multiple plans, and multiple similiar plans can have different users
                      * so each plan - user pair has a unique id lol. 
                      */

                     bytes32 _planId = keccak256(abi.encodePacked(msg.sender)); 

                     planByPlanId[_planId] = newPlan;
                     require(newPlan.swapsExecuted == 0 && newPlan.remainingBalance ==0, "");
                     userPlan[msg.sender] = newPlan;
                     
                     newPlan.interval = _interval;
                     newPlan.investmentPerSwap = _investmentPerSwap;
                     newPlan.swapsExecuted = 0;
                     newPlan.remainingBalance = 0;

                     emit PlanCreated(msg.sender, _planId);
       }

       function depositFunds(uint256 amount, bytes32 _planId) public {
              require(amount>0, "deposit sumt");
              require(msg.sender == userOfPlan[_planId], "invalid plan id");

              require(amount<= IERC20(i_baseToken).balanceOf(msg.sender));

              userPlan[msg.sender].remainingBalance+= amount;
              IERC20(i_baseToken).transferFrom(msg.sender, address(this), amount);

              emit DepositMade(msg.sender, amount);
       }

       /** 
        * the router by obvious reasons does not itself hold and liquidity, it rather finds the relevant 
        * uniswapV2pair (on-chain) contract via the factory.
        */

       function swapTheTokens(bytes32 planId) external {
              DCAPlan memory plan = planByPlanId[planId];

              if(plan.swapsExecuted == 0) {
                     require(msg.sender == userOfPlan[planId]);
              } else {
                     require(msg.sender == i_automationRegistryAddress, "further investments are automated");
              }
              require(plan.remainingBalance>=plan.investmentPerSwap, "no possible swapping for remaining amount");

              uint256 amount = planByPlanId[planId].investmentPerSwap;
              IERC20(i_baseToken).approve(i_uniswapv2router, amount);

              address[] memory path;
              path[0] = i_baseToken;
              path[1] = i_targetToken;

              uint256 amountOutMin = IUniswapV2RouterCustom(i_uniswapv2router).getAmountsOut(amount, path)[1];

              IUniswapV2RouterCustom(i_uniswapv2router).swapExactTokensForTokens(
                     amount,
                     amountOutMin,
                     path,
                     address(this),
                     block.timestamp + 10 minutes
              );
       }

       // what would react to first investment made? 
       // gotta run this logic for each plan. 

       function checkUpkeep(bytes calldata checkData) external view override returns (bool upKeepNeeded, bytes memory performData) {
              bytes32 planId = abi.decode(checkData, (bytes32));
              
              bool firstInvestmentMade;
              bool timeForNextExecution;

              if (planByPlanId[planId].swapsExecuted >0) {
                     firstInvestmentMade == true;
              }

              

       }

       function performUpkeep(bytes calldata) public override {

       }

       function totalBaseInContract() public view returns (uint256) {
              return IERC20(i_baseToken).balanceOf(address(this));
       }
}