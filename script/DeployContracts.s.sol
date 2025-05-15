// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import { BaseScript } from "./Base.s.sol";
import { DeploymentConfig } from "./DeploymentConfig.s.sol";
import { CommunityOwnerTokenFactory } from "../contracts/factories/CommunityOwnerTokenFactory.sol";
import { CommunityMasterTokenFactory } from "../contracts/factories/CommunityMasterTokenFactory.sol";
import { CommunityOwnerTokenRegistry } from "../contracts/CommunityOwnerTokenRegistry.sol";
import { CommunityTokenDeployer } from "../contracts/CommunityTokenDeployer.sol";

contract DeployContracts is BaseScript {
    function run()
        external
        returns (
            CommunityTokenDeployer,
            CommunityOwnerTokenRegistry,
            CommunityOwnerTokenFactory,
            CommunityMasterTokenFactory,
            DeploymentConfig
        )
    {
        DeploymentConfig deploymentConfig = new DeploymentConfig(broadcaster);

        vm.startBroadcast(broadcaster);
        CommunityOwnerTokenFactory ownerTokenFactory = new CommunityOwnerTokenFactory();
        CommunityMasterTokenFactory masterTokenFactory = new CommunityMasterTokenFactory();
        CommunityOwnerTokenRegistry tokenRegistry = new CommunityOwnerTokenRegistry();
        CommunityTokenDeployer tokenDeployer =
            new CommunityTokenDeployer(address(tokenRegistry), address(ownerTokenFactory), address(masterTokenFactory));

        tokenRegistry.setCommunityTokenDeployerAddress(address(tokenDeployer));
        ownerTokenFactory.setTokenDeployerAddress(address(tokenDeployer));
        masterTokenFactory.setTokenDeployerAddress(address(tokenDeployer));
        vm.stopBroadcast();

        return (tokenDeployer, tokenRegistry, ownerTokenFactory, masterTokenFactory, deploymentConfig);
    }

    // This function is a hack to have it excluded by `forge coverage` until
    // https://github.com/foundry-rs/foundry/issues/2988 is fixed.
    // See: https://github.com/foundry-rs/foundry/issues/2988#issuecomment-1437784542
    // for more info.
    // solhint-disable-next-line
    function test() public { }
}
