// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {AggregatorV3Interface} from "@chainlink-contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

//_______________________
// ERROR
//_______________________

error OracleIntegration__InvalidPriceFeed();
error OracleIntegration__InvalidAmount();
error OracleIntegration__InvalidRoundId();
error OracleIntegration__FromFuture();
error OracleIntegration__InvalidTokenType();
error OracleIntegration__StalePrice();
error OracleIntegration__PriceIsNotValid();

/*
* @title OracleIntegration
* @author 0xNicos
* @dev use Chainlink DataFeed for priceFeeds.
* @notice this is contract gets data from the chainlink nodes validate the data and store
			the data internally for onchain verificatons of ETH/USD price. 
*/

contract OracleIntegration {
    //_______________________
    // STATE VARIABLES
    //_______________________

    AggregatorV3Interface private immutable i_priceFeed;
    uint256 private s_lastPrice;
    uint256 private s_lastTimestamp;
    uint256 private s_maxPriceAge = 2 minutes;
    uint80 private s_roundId;

    mapping(uint256 => uint256) private s_historicalPrices;

    //_______________________
    // ENUM
    //_______________________

    enum TokenType {
        ETH,
        USD
    }

    //_______________________
    // EVENTS
    //_______________________

    event PriceUpdated(uint256 indexed price, uint80 indexed roundId, uint256 timeStamp);

    constructor(address priceFeed) {
        if (priceFeed == address(0)) {
            revert OracleIntegration__InvalidPriceFeed();
        }

        i_priceFeed = AggregatorV3Interface(priceFeed);
        s_lastTimestamp = block.timestamp;
    }

    /// @notice this functions calls on the orcale to get the lastest data.
    /// @dev get the newest data from the orcale. validate each data before usage.
    function fetchLatestPrice() public returns (uint256) {
        (uint80 roundId, int256 price,, uint256 updatedAt,) = i_priceFeed.latestRoundData();

        if (price == 0) {
            revert OracleIntegration__InvalidPriceFeed();
        }

        if (roundId == 0) {
            revert OracleIntegration__InvalidRoundId();
        }

        if (updatedAt > block.timestamp) {
            revert OracleIntegration__FromFuture();
        }

        uint256 scaledPrice = (uint256(price * 1e10));

        storePrice(scaledPrice, roundId, updatedAt);

        return scaledPrice;
    }

    /// @notice  this function helps to validate the returned values from the orcale.
    /// @dev aviod using stale or old data ensure all data meets the lastest required.
    function validatePrice() public view {
        uint256 price = s_lastPrice;
        uint256 timeStamp = s_lastTimestamp;

        if (price == 0) {
            revert OracleIntegration__PriceIsNotValid();
        }

        if (block.timestamp - timeStamp > s_maxPriceAge) {
            revert OracleIntegration__StalePrice();
        }
    }

    /// @notice this function store the price internally.
    /// dev update the lastePrice to the lastest stores it for internal use.
    function storePrice(uint256 price, uint80 roundId, uint256 timeStamp) internal {
        s_lastPrice = price;
        s_lastTimestamp = timeStamp;
        s_roundId = roundId;
        s_historicalPrices[roundId] = price;

        emit PriceUpdated(price, roundId, timeStamp);
    }

    /// notice this functions calls on the converstions using the token Type.
    function usePrice(uint256 amount, uint256 tokenType) public view returns (uint256) {
        if (amount == 0) {
            revert OracleIntegration__InvalidAmount();
        }

        if (tokenType > 2) {
            revert OracleIntegration__InvalidTokenType();
        }

        TokenType _tokenType = TokenType(tokenType);

        if (_tokenType == TokenType.ETH) {
            return convertETHToUsd(amount);
        } else if (_tokenType == TokenType.USD) {
            return convertUsdToETH(amount);
        }

        return 0;
    }

    /*
    * @notice this function convert the price of ETH to Usd
    * @dev use the price stored from the oracle to get the convertion rate of eth to usd. 
    */
    function convertETHToUsd(uint256 amount) internal view returns (uint256) {
        uint256 price = s_lastPrice;
        uint256 usdAmount = (price * amount) / 1e10;
        return usdAmount;
    }

    /*
    * @notice convert Usd to ETH.
    * @dev use the price from the orcale to get the lastes conversion of USD to ETH.
    */
    function convertUsdToETH(uint256 amount) internal view returns (uint256) {
        uint256 price = s_lastPrice;
        uint256 ethAmount = (amount * 1e10) / price;
        return ethAmount;
    }

    //_______________________
    // Getters
    //_______________________

    function getDecimals() external view returns (uint8) {
        return AggregatorV3Interface(i_priceFeed).decimals();
    }

    function getHistoricalPrice(uint256 roundId) external view returns (uint256) {
        return s_historicalPrices[roundId];
    }

    function getLatestPrice() external view returns (uint256) {
        return s_lastPrice;
    }

    function getVersion() external view returns (uint256) {
        return AggregatorV3Interface(i_priceFeed).version();
    }

    function getLastRoundId() external view returns (uint80) {
        return s_roundId;
    }

    function getMaxPriceAge() external view returns (uint256) {
        return s_maxPriceAge;
    }

    function getPriceFeedAddress() external view returns (address) {
        return address(i_priceFeed);
    }

    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimestamp;
    }
}
