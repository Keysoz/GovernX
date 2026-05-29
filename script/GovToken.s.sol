// SPDX-License-Identifier: MIT
pragma solidity 0.8.35;

import {Script} from "forge-std/Script.sol";
import {GovernX} from "../src/GovToken.sol";
import {console} from "forge-std/console.sol";

contract DeployGovernX is Script {
    function run() external returns (GovernX) {
        string name = "Governor X Token";
        string symbol = "GVX";
        GovernX governor;

        vm.startBroadcast();
        governor = new GovernX(name, symbol);
        vm.stopBroadcast();
        return governor;
        // after deployment:
        console.log("GovernX deployed at:", address(governor));
    }
}
