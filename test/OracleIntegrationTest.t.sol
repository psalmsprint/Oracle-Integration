// SPDX-License-Identifer: MIT

pragma solidity ^0.8.30;

import {Test, stdError} from "forge-std/Test.sol";
import "../src/OracleIntegration.sol";
import {DeployOracleIntegration} from "../script/DeployOracleIntegration.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {MockV3Aggregator} from "@chainlink-contracts/src/v0.8/tests/MockV3Aggregator.sol";
import {BadPriceMock, BadRoundIdMock, BadUpdateAtMock} from "./mocks/BadMock.sol";

contract OracleIntegrationTest is Test {
    OracleIntegration oracle;
    DeployOracleIntegration deployer;
    HelperConfig helper;

    address public priceFeed;

    address user = makeAddr("user");

    uint256 private constant ETH_AMOUNT = 10e18;
    uint256 private constant USD_AMOUNT = 100e8;

    event PriceUpdated(uint256 indexed price, uint80 indexed roundId, uint256 timeStamp);

    function setUp() external {
        deployer = new DeployOracleIntegration();
        (oracle, helper) = deployer.run();

        priceFeed = helper.activeNetworkConfig();
    }

    //_____________________
    // constructor
    //_____________________

    function testConstructorRevertWhenPriceFeedisZero() public {
        vm.expectRevert(OracleIntegration__InvalidPriceFeed.selector);
        new OracleIntegration(address(0));
    }

    function testConstructorPassAndSetSatae() public {
        OracleIntegration oracleIntegration = new OracleIntegration(priceFeed);
        assertEq(oracleIntegration.getPriceFeedAddress(), priceFeed);
        assertEq(oracleIntegration.getLastTimeStamp(), block.timestamp);
    }

    //_____________________
    // FetchLatestPrice
    //_____________________

    function testFetchLatestPriceRevertWhenPriceIsZero() public {
        BadPriceMock badPriceMock = new BadPriceMock();

        OracleIntegration oracleIntegration = new OracleIntegration(address(badPriceMock));

        vm.expectRevert(OracleIntegration__InvalidPriceFeed.selector);
        oracleIntegration.fetchLatestPrice();
    }

    function testFetchLatsestPriceRevertWhenRoundIdIsZero() public {
        BadRoundIdMock badRoundIdMock = new BadRoundIdMock();

        OracleIntegration oracleIntegration = new OracleIntegration(address(badRoundIdMock));

        vm.expectRevert(OracleIntegration__InvalidRoundId.selector);
        oracleIntegration.fetchLatestPrice();
    }

    function testFetchLatestPriceRevertUpdateApIsZero() public {
        BadUpdateAtMock badUpdateAtMock = new BadUpdateAtMock();

        OracleIntegration oracleIntegration = new OracleIntegration(address(badUpdateAtMock));

        vm.expectRevert(OracleIntegration__FromFuture.selector);
        oracleIntegration.fetchLatestPrice();
    }

    function testFetchLatestPricePassedAndUpdateState() public {
        uint256 price = oracle.fetchLatestPrice();

        assertEq(oracle.getLatestPrice(), price);
        assertEq(oracle.getLastRoundId(), 1);
        assertEq(oracle.getLastTimeStamp(), block.timestamp);
    }

    //_____________________
    // ValidatePrice
    //_____________________

    function testValidatePriceRevertWhenPriceIsZero() public {
        BadPriceMock badPriceMock = new BadPriceMock();

        OracleIntegration oracleIntegration = new OracleIntegration(address(badPriceMock));

        vm.expectRevert(OracleIntegration__PriceIsNotValid.selector);
        oracleIntegration.validatePrice();
    }

    function testValidatePriceRevertWhenPriceIsStale() public {
        oracle.fetchLatestPrice();

        vm.warp(block.timestamp + 10 days);

        vm.expectRevert(OracleIntegration__StalePrice.selector);
        oracle.validatePrice();
    }

    function testValidatePricePassed() public {
        oracle.fetchLatestPrice();

        oracle.validatePrice();
    }

    //_____________________
    // StorePrice
    //_____________________

    function test_FuzzStorePriceUpdateStateAndEmitEvent(uint256 price, uint80 roundId, uint256 timeStamp) public {
        vm.assume(price > 1e8 && price < 5e8);
        vm.assume(roundId > 0);
        vm.assume(timeStamp > 1);

        vm.expectEmit(true, true, false, false);
        emit PriceUpdated(price, roundId, timeStamp);

        oracle.storePrice(price, roundId, timeStamp);

        assertEq(oracle.getLatestPrice(), price);
        assertEq(oracle.getLastRoundId(), roundId);
        assertEq(oracle.getLastTimeStamp(), timeStamp);
        assertEq(oracle.getHistoricalPrice(roundId), price);
    }

    //_____________________
    // UsePrice
    //_____________________

    /// forge-config: default.allow_internal_expect_revert = true
    function testUsePriceRevertWhenPassedInValidTokenType(uint256 tokenType) public {
        vm.assume(tokenType > 2);
        uint256 amount = 1 ether;

        oracle.fetchLatestPrice();

        vm.expectRevert(OracleIntegration__InvalidTokenType.selector);
        oracle.usePrice(amount, tokenType);
    }

    function testUsePriceRevertWhenAmountIsZero() public {
        uint256 tokenType = 1;
        uint256 amount = 0;

        vm.expectRevert(OracleIntegration__InvalidAmount.selector);
        oracle.usePrice(amount, tokenType);
    }

    function test_fuzzUsePriceIsConsistentConvertingETHToUSD(uint256 amount) public {
        vm.assume(amount > 1e18 && amount < 5e18);
        uint256 tokenType = 0;

        uint256 price = oracle.fetchLatestPrice();

        uint256 returnValue = oracle.usePrice(amount, tokenType);

        uint256 expectedPrice = price * amount / 1e10;

        assertEq(expectedPrice, returnValue);
    }

    function test_fuzzUsePriceConvertingUSDToETHIsConsistent(uint256 amount) public {
        vm.assume(amount > 1e8 && amount < 5e8);
        uint256 tokenType = 1;

        uint256 price = oracle.fetchLatestPrice();

        uint256 returnedETH = oracle.usePrice(amount, tokenType);

        uint256 expectedETH = (amount * 1e10) / price;

        assertEq(returnedETH, expectedETH);
    }

    //_____________________
    // Getters
    //_____________________

    function testGetVersionIsConsistent() public view {
        uint256 version = 5;

        assertEq(oracle.getVersion(), version);
    }

    function testDecimalIsConsistent() public view {
        uint8 decimals = 8;

        assertEq(oracle.getDecimals(), decimals);
    }

    function testMaxAgeIsConsistent() public {
        uint256 maxAge = oracle.getMaxPriceAge();

        oracle.fetchLatestPrice();

        vm.warp(block.timestamp + 100 days);

        assertEq(oracle.getMaxPriceAge(), maxAge);
    }
}
