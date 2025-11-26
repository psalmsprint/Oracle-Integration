// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {OracleIntegration} from "../src/OracleIntegration.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployOracleIntegration is Script {
    function run() external returns (OracleIntegration, HelperConfig) {
        HelperConfig helper = new HelperConfig();

        address priceFeeds = helper.activeNetworkConfig();

        vm.startBroadcast();
        OracleIntegration orcale = new OracleIntegration(priceFeeds);

        vm.stopBroadcast();

        return (orcale, helper);
    }
}
