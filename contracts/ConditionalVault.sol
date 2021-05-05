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

contract ConditionalVault is Ownable {
    address[] public tokenWhitelist;

    enum ComparisonOperator {GREATER_THAN, LESSER_THAN, EQUAL_TO}

    struct ConditionLockedDeposit {
        address tokenAddress;
        address conditionOracleAddress;
        int256 requiredOracleAnswer;
        ComparisonOperator conditionOperator;
        uint256 amount;
        uint256 timestamp;
    }

    mapping(address => mapping(address => uint256)) public balances;

    function deposit(address _tokenAddress, uint256 amount) external {
        require(isWhitelisted(_tokenAddress), "token is not on whitelist");

        require(
            IERC20(_tokenAddress).transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            "token transfer failed"
        );
        balances[msg.sender][_tokenAddress] += amount;
    }

    function whitelistToken(address _tokenAddress) external onlyOwner {
        // check to ensure address is valid token before adding
        require(IERC20(_tokenAddress).balanceOf(address(this)) >= 0);
        tokenWhitelist.push(_tokenAddress);
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
