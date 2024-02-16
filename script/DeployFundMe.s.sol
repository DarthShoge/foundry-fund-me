pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";


contract DeployFundMe is Script {
    function run() public returns(FundMe) {
        HelperConfig helperConfig = new HelperConfig();
        (address usdPriceFeed) = helperConfig.activeConfig();

        vm.startBroadcast();
        FundMe fundMe = new FundMe(usdPriceFeed);
        vm.stopBroadcast();
        return fundMe;
    }
}