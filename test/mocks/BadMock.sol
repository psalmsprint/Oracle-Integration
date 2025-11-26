// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract BadPriceMock {
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (0, 0, block.timestamp, block.timestamp + 3 days, 0);
    }
}

contract BadRoundIdMock {
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (0, 3000e8, block.timestamp, block.timestamp + 3 days, 0);
    }
}

contract BadUpdateAtMock {
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (1, 4000e8, block.timestamp, block.timestamp + 3 days, 0);
    }
}
