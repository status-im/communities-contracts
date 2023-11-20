// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";
import { CommunityVault } from "../contracts/CommunityVault.sol";
import { DeploymentConfig } from "../script/DeploymentConfig.s.sol";
import { DeployOwnerAndMasterToken } from "../script/DeployOwnerAndMasterToken.s.sol";
import { CommunityERC20 } from "../contracts/tokens/CommunityERC20.sol";
import { OwnerToken } from "../contracts/tokens/OwnerToken.sol";
import { MasterToken } from "../contracts/tokens/MasterToken.sol";

contract CommunityVaultTest is Test {
    CommunityVault internal vault;

    address[] internal accounts = new address[](4);
    address internal deployer;

    CommunityERC20 internal erc20Token;
    OwnerToken internal ownerToken;
    MasterToken internal masterToken;

    function setUp() public {
        DeploymentConfig deploymentConfig;
        DeployOwnerAndMasterToken deployment = new DeployOwnerAndMasterToken();
        (ownerToken, masterToken, deploymentConfig) = deployment.run();

        deployer = deploymentConfig.deployer();

        erc20Token = new CommunityERC20(
            "Test",
            "TEST",
            18,
            100,
            "",
            address(ownerToken),
            address(masterToken)
        );

        vault = new CommunityVault(address(ownerToken), address(masterToken));
    }

    function test_Deployment() public {
        assertEq(vault.ownerToken(), address(ownerToken));
        assertEq(vault.masterToken(), address(masterToken));
    }
}
