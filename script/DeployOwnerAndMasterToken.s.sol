// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import { BaseScript } from "./Base.s.sol";
import { DeploymentConfig } from "./DeploymentConfig.s.sol";
import { OwnerToken } from "../contracts/tokens/OwnerToken.sol";
import { MasterToken } from "../contracts/tokens/MasterToken.sol";

contract DeployOwnerAndMasterToken is BaseScript {
    function run() external returns (OwnerToken, MasterToken, DeploymentConfig) {
        DeploymentConfig deploymentConfig = new DeploymentConfig(broadcaster);
        DeploymentConfig.TokenConfig memory ownerTokenConfig = deploymentConfig.getOwnerTokenConfig();
        DeploymentConfig.TokenConfig memory masterTokenConfig = deploymentConfig.getMasterTokenConfig();

        vm.startBroadcast(broadcaster);
        OwnerToken ownerToken = new OwnerToken(
            ownerTokenConfig.name,
            ownerTokenConfig.symbol,
            ownerTokenConfig.baseURI,
            broadcaster,
            ownerTokenConfig.signerPublicKey
        );

        MasterToken masterToken = new MasterToken(
            masterTokenConfig.name,
            masterTokenConfig.symbol,
            masterTokenConfig.baseURI,
            address(ownerToken)
        );
        vm.stopBroadcast();

        return (ownerToken, masterToken, deploymentConfig);
    }

    // This function is a hack to have it excluded by `forge coverage` until
    // https://github.com/foundry-rs/foundry/issues/2988 is fixed.
    // See: https://github.com/foundry-rs/foundry/issues/2988#issuecomment-1437784542
    // for more info.
    // solhint-disable-next-line
    function test() public { }
}
