// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// things i want this to do:
// deposit ETH / tokens
// deposit that into yearn v2 (zap eth into STETH? check return?)

// timelock:
// dont allow withdraw before timestamp

// condition lock:
// dont allow withdraw if condition returns false (chainlink oracle report)

// slash 5% for emergency withdraw

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./PriceConsumerV3.sol";

import "hardhat/console.sol";

contract ConditionalVault is Ownable, PriceConsumerV3 {
    address[] public tokenWhitelist;

    enum ComparisonOperator {
        GREATER_THAN,
        GREATER_THAN_OR_EQUAL_TO,
        LESS_THAN,
        LESS_THAN_OR_EQUAL_TO,
        EQUAL_TO
    }

    struct ConditionLockedDeposit {
        address tokenAddress;
        address conditionOracleAddress;
        int256 conditionOracleValue;
        ComparisonOperator conditionOperator;
        uint256 amount;
        uint256 timestamp;
    }

    mapping(address => ConditionLockedDeposit[]) public conditionLockedDeposits;

    event NewConditionLockedDeposit(
        ConditionLockedDeposit conditionLockedDeposit
    );

    function createConditionLockedDeposit(
        address _tokenAddress,
        address _conditionOracleAddress,
        int256 _conditionOracleValue,
        uint8 _conditionOperator,
        uint256 _amount
    ) external {
        require(isWhitelisted(_tokenAddress), "token is not on whitelist");

        require(
            IERC20(_tokenAddress).transferFrom(
                msg.sender,
                address(this),
                _amount
            ),
            "token transfer to contract failed"
        );

        conditionLockedDeposits[msg.sender].push(
            ConditionLockedDeposit(
                _tokenAddress,
                _conditionOracleAddress,
                _conditionOracleValue,
                ComparisonOperator(_conditionOperator),
                _amount,
                block.timestamp
            )
        );

        ConditionLockedDeposit[] memory deposits =
            conditionLockedDeposits[msg.sender];

        emit NewConditionLockedDeposit(deposits[deposits.length - 1]);
    }

    function whitelistToken(address _tokenAddress) external onlyOwner {
        require(!isWhitelisted(_tokenAddress), "token already whitelisted");
        require(IERC20(_tokenAddress).balanceOf(address(this)) >= 0, "invalid token address");

        tokenWhitelist.push(_tokenAddress);
    }

    function conditionSatisfied(address _owner, uint256 _depositIndex) public view returns (bool) {
      ConditionLockedDeposit memory deposit = conditionLockedDeposits[_owner][_depositIndex];
      (, int256 price, , ,) = getLatestRoundDataFor(deposit.conditionOracleAddress);

      console.logInt(price);

      // this is more gas efficient than assembly switch
      if (deposit.conditionOperator == ComparisonOperator.GREATER_THAN) {
        return(price > deposit.conditionOracleValue);
      } else if (deposit.conditionOperator == ComparisonOperator.LESS_THAN) {
        return(price < deposit.conditionOracleValue);
      } else if (deposit.conditionOperator == ComparisonOperator.GREATER_THAN_OR_EQUAL_TO) {
        return(price >= deposit.conditionOracleValue);
      } else if (deposit.conditionOperator == ComparisonOperator.LESS_THAN_OR_EQUAL_TO) {
        return(price <= deposit.conditionOracleValue);
      } else if (deposit.conditionOperator == ComparisonOperator.EQUAL_TO) {
        return(price == deposit.conditionOracleValue);
      } else {
        revert("invalid comparison operator in deposit");
      }
    }

    function isWhitelisted(address _tokenAddress) internal view returns (bool) {
        for (uint256 i = 0; i < tokenWhitelist.length; i++) {
            if (tokenWhitelist[i] == _tokenAddress) {
                return true;
            }
        }
        return false;
    }
}
