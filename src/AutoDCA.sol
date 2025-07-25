//SPDX-License-Identifier
pragma solidity ^0.8.20;

import {IERC20} from "../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";

abstract contract Parameters {
       address private immutable i_baseToken;
       address private immutable i_TargetToken;
       address private immutable i_uniswapv2router;
}

interface IDCAEvents {
       event PlanCreated(address indexed user, bytes32 planId);
       event DepositMade(address indexed user, uint256 amount);
       event SwapExecuted(address indexed user, uint256 amount, uint256 timestamp);
}

interface IUniswapV2RouterCustom {
       function swapExactTokensForTokens(
              uint256 amountIn,
              uint256 amountOutMin,
              address[] calldata path,
              address to,
              uint256 deadline
       ) external returns (uint256[] memory amounts);

       function getAmountsOut(
              uint256 amountIn,
              address[] calldata path
       ) external view returns (uint256[] memory amounts);

       // function WETH() external pure returns (address);
}

contract AutoDCAInvestmentTool is Parameters, IDCAEvents{
       using Parameters for address;
       /**
        * @dev a struct that defines the dollar cost averaging plan for a user
        * @param baseToken is the stable coin that the user would invest
        * @param targetToken is the ERC20 that the uniswap router would swap for the user
        * @param interval is the time interval in which the investments will be automated in 
        * @param amountPerSwap is the amount of stable coins which each user would like to invest on each interval
        * @param swapslExecuted is the time of total investments of the investment plan ? update lastExecution
        * @param remainingBalance ? reduce remainingBalance
        */
       struct DCAPlan {
              bytes32 planId;
              uint256 interval; 
              uint256 amountPerSwap;
              uint256 swapsExecuted;
              uint256 remainingBalance; 
       }

       mapping (address => DCAPlan) userPlan;

       constructor (address stableCoin, address targetCoin, address router) {
              i_baseToken = stableCoin;
              i_targetToken = targetCoin;

              i_uniswapv2router = router;
       }

       function createPlan(
              uint256 _interval,
              uint256 _investmentPerSwap,
              uint256 _numberOfSwaps) 
              external returns (DCAPlan memory newPlan) {
                     require(_interval>0 && _interval< 4 weeks);
                     require(_investmentPerSwap>0, "must invest coins");
                     require(_numberOfSwaps>0, "atleast 1 swap");

                     bytes32 _planId = keccak256(abi.encodePacked(bytes32(msg.sender)));
                     userPlan[msg.sender] = newPlan;

                     // IERC20.(i_BASE_TOKEN).transferFrom(msg.sender, address(this), initialDeposit);

                     newPlan.planId = _planId;
                     newPlan.interval = _interval;
                     newPlan.investmentPerSwap = _investmentPerSwap;
                     newPlan.numberOfSwaps = _numberOfSwaps;
                     newPlan.remainingBalance = initialDeposit;

                     emit PlanCreated(msg.sender, _planId);
       }

       function depositFunds(uint256 amount, bytes32 _planId) public {
              require(amount>0, "deposit sumt");
              require(userPlan[msg.sender].planId == _planId, "invalid plan id");
              require(amount>= (userPlan[msg.sender].investmentPerSwap)*(userPlan[msg.sender].totalExecutions));

              require(amount<= IERC20(i_baseToken).balanceOf(msg.sender));

              userPlan[msg.sender].remainingBalance+= amount;
              baseToken.transferFrom(msg.sender, address(this), amount);

              emit DepositMade(msg.sender, amount);
       }

       function swapTheTokens() external {
              IERC20(i_baseToken).approve(IUniswapV2Router, amount);
              address[] memory path;
              path[0] = i_baseToken;
              path[1] = i_targetToken;

              IUniswapV2Router(i_uniswapv2router).swapExactTokensForTokens(
                     amount,
                     amountOutMin,
                     path,
                     address(this),
                     block.timestamp + 24 hours
              );
       }

       function totalBaseInContract() public view returns (uint256) {
              return IERC20(i_BASE_TOKEN).balanceOf(address(this));
       }
}