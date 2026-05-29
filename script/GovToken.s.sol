// SPDX-License-Identifier: MIT
pragma solidity 0.8.35;

import {Script} from "forge-std/Script.sol";
import {GovernX} from "../src/GovToken.sol";

contract DeployGovernX is Script {
    string name = "Governor X Token";
    string symbol = "GVX";
    GovernX governor;

    function run() external returns (GovernX) {
        vm.startBroadcast();
        governor = new GovernX(name, symbol);
        vm.stopBroadcast();
        return governor;
    }
}
