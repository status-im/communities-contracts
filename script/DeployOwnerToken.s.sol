// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import { Vm } from "forge-std/Vm.sol";
import { BaseScript } from "./Base.s.sol";
import { DeploymentConfig } from "./DeploymentConfig.s.sol";
import { OwnerToken } from "../contracts/OwnerToken.sol";
import { MasterToken } from "../contracts/MasterToken.sol";

contract DeployOwnerToken is BaseScript {
    function run() external returns (OwnerToken, MasterToken, DeploymentConfig) {
        DeploymentConfig deploymentConfig = new DeploymentConfig(broadcaster);
        DeploymentConfig.TokenConfig memory ownerTokenConfig = deploymentConfig.getOwnerTokenConfig();
        DeploymentConfig.TokenConfig memory masterTokenConfig = deploymentConfig.getMasterTokenConfig();

        vm.recordLogs();
        vm.startBroadcast(broadcaster);
        OwnerToken ownerToken = new OwnerToken(
      ownerTokenConfig.name,
      ownerTokenConfig.symbol,
      ownerTokenConfig.baseURI,
      masterTokenConfig.name,
      masterTokenConfig.symbol,
      masterTokenConfig.baseURI,
      ownerTokenConfig.signerPublicKey
    );

        // Need to retrieve master token address from logs as
        // we can't access it otherwise
        Vm.Log[] memory entries = vm.getRecordedLogs();
        address masterTokenAddress = abi.decode(entries[0].data, (address));

        MasterToken masterToken = MasterToken(masterTokenAddress);
        vm.stopBroadcast();

        return (ownerToken, masterToken, deploymentConfig);
    }
}
