// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceConsumerV3 {
    function getLatestRoundDataFor(address _priceFeed)
        public
        view
        returns (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_priceFeed);

        return priceFeed.latestRoundData();
    }

    function getPriceFeedInterface(address _priceFeed) public pure returns (AggregatorV3Interface) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_priceFeed);
        return priceFeed;
    }
}
