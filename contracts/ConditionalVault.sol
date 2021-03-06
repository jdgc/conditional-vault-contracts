// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./PriceConsumerV3.sol";
import "./TokenWhitelist.sol";

contract ConditionalVault is Ownable, PriceConsumerV3, TokenWhitelist {
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

    event NewConditionLockedDeposit(ConditionLockedDeposit conditionLockedDeposit);

    function createConditionLockedDeposit(
        address _tokenAddress,
        address _conditionOracleAddress,
        int256 _conditionOracleValue,
        uint8 _conditionOperator,
        uint256 _amount
    ) external {
        require(isWhitelisted(_tokenAddress), "token is not on whitelist");

        require(
            IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount),
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

        ConditionLockedDeposit[] memory deposits = conditionLockedDeposits[msg.sender];

        emit NewConditionLockedDeposit(deposits[deposits.length - 1]);
    }

    function withdrawConditionLockedDeposit(uint256 _depositIndex) external {
        require(conditionSatisfied(msg.sender, _depositIndex), "withdraw condition not satisfied");

        ConditionLockedDeposit memory deposit = conditionLockedDeposits[msg.sender][_depositIndex];
        require(
            IERC20(deposit.tokenAddress).balanceOf(address(this)) >= deposit.amount,
            "not enough contract balance to satisfy withdraw request"
        );
        delete conditionLockedDeposits[msg.sender][_depositIndex];

        require(
            IERC20(deposit.tokenAddress).transfer(msg.sender, deposit.amount),
            "token transfer failed"
        );
    }

    function conditionSatisfied(address _owner, uint256 _depositIndex) public view returns (bool) {
        ConditionLockedDeposit memory deposit = conditionLockedDeposits[_owner][_depositIndex];
        (, int256 price, , , ) = getLatestRoundDataFor(deposit.conditionOracleAddress);

        bool isSatisfied;

        if (deposit.conditionOperator == ComparisonOperator.GREATER_THAN) {
            isSatisfied = (price > deposit.conditionOracleValue);
        } else if (deposit.conditionOperator == ComparisonOperator.LESS_THAN) {
            isSatisfied = (price < deposit.conditionOracleValue);
        } else if (deposit.conditionOperator == ComparisonOperator.GREATER_THAN_OR_EQUAL_TO) {
            isSatisfied = (price >= deposit.conditionOracleValue);
        } else if (deposit.conditionOperator == ComparisonOperator.LESS_THAN_OR_EQUAL_TO) {
            isSatisfied = (price <= deposit.conditionOracleValue);
        } else if (deposit.conditionOperator == ComparisonOperator.EQUAL_TO) {
            isSatisfied = (price == deposit.conditionOracleValue);
        } else {
            revert("invalid comparison operator in deposit");
        }

        return isSatisfied;
    }
}
