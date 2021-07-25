// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenWhitelist is Ownable {
    address[] public tokenWhitelist;

    address private constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;

    function whitelistToken(address _tokenAddress) external onlyOwner {
        require(!isWhitelisted(_tokenAddress), "token already whitelisted");
        require(IERC20(_tokenAddress).balanceOf(address(this)) >= 0, "invalid token address");

        tokenWhitelist.push(_tokenAddress);
    }

    function removeFromWhitelist(uint256 _index) external onlyOwner {
        for (uint256 i = _index; i < tokenWhitelist.length - 1; i++) {
            tokenWhitelist[i] = tokenWhitelist[i + 1];
        }

        delete tokenWhitelist[tokenWhitelist.length - 1];
    }

    function isWhitelisted(address _tokenAddress) public view returns (bool) {
        for (uint256 i = 0; i < tokenWhitelist.length; i++) {
            if (tokenWhitelist[i] == _tokenAddress) {
                return true;
            }
        }
        return false;
    }
}
