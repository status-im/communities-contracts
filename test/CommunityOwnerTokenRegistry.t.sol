// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";
import { DeployContracts } from "../script/DeployContracts.s.sol";
import { DeploymentConfig } from "../script/DeploymentConfig.s.sol";
import { CommunityOwnerTokenRegistry } from "../contracts/CommunityOwnerTokenRegistry.sol";
import { CommunityTokenDeployer } from "../contracts/CommunityTokenDeployer.sol";

contract CommunityOwnerTokenRegistryTest is Test {
    event TokenDeployerAddressChange(address indexed);
    event AddEntry(address indexed, address indexed);

    DeploymentConfig internal deploymentConfig;

    CommunityTokenDeployer internal tokenDeployer;

    CommunityOwnerTokenRegistry internal tokenRegistry;

    address internal deployer;

    address internal tokenDeployerAccount = makeAddr("tokenDeployer");

    address internal communityAddress = makeAddr("communityAddress");

    address internal tokenAddress = makeAddr("tokenAddress");

    function setUp() public virtual {
        DeployContracts deployment = new DeployContracts();
        (tokenDeployer, tokenRegistry,,, deploymentConfig) = deployment.run();
        deployer = deploymentConfig.deployer();
    }
}

contract DeploymentTest is CommunityOwnerTokenRegistryTest {
    function setUp() public virtual override {
        CommunityOwnerTokenRegistryTest.setUp();
    }

    function test_Deployment() public {
        assertEq(tokenDeployer.owner(), deployer);
        assertEq(tokenRegistry.tokenDeployer(), address(tokenDeployer));
    }
}

contract SetCommunityTokenDeployerAddressTest is CommunityOwnerTokenRegistryTest {
    function setUp() public virtual override {
        CommunityOwnerTokenRegistryTest.setUp();
    }

    function test_RevertWhen_SenderIsNotOwner() public {
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        tokenRegistry.setCommunityTokenDeployerAddress(makeAddr("someAddress"));
    }

    function test_RevertWhen_InvalidTokenDeployerAddress() public {
        vm.prank(deployer);
        vm.expectRevert(CommunityOwnerTokenRegistry.CommunityOwnerTokenRegistry_InvalidAddress.selector);
        tokenRegistry.setCommunityTokenDeployerAddress(address(0));
    }

    function test_SetCommunityTokenDeployerAddress() public {
        address newAddress = makeAddr("someAddress");
        vm.prank(deployer);
        vm.expectEmit(true, true, true, false);
        emit TokenDeployerAddressChange(newAddress);
        tokenRegistry.setCommunityTokenDeployerAddress(newAddress);
        assertEq(tokenRegistry.tokenDeployer(), newAddress);
    }
}

contract AddEntryTest is CommunityOwnerTokenRegistryTest {
    function setUp() public virtual override {
        CommunityOwnerTokenRegistryTest.setUp();
        vm.prank(deployer);
        tokenRegistry.setCommunityTokenDeployerAddress(tokenDeployerAccount);
    }

    function test_RevertWhen_SenderIsNotTokenDeployer() public {
        vm.expectRevert(CommunityOwnerTokenRegistry.CommunityOwnerTokenRegistry_NotAuthorized.selector);
        tokenRegistry.addEntry(communityAddress, tokenAddress);
    }

    function test_RevertWhen_InvalidAddress() public {
        vm.startPrank(tokenDeployerAccount);
        vm.expectRevert(CommunityOwnerTokenRegistry.CommunityOwnerTokenRegistry_InvalidAddress.selector);
        tokenRegistry.addEntry(address(0), tokenAddress);
        vm.expectRevert(CommunityOwnerTokenRegistry.CommunityOwnerTokenRegistry_InvalidAddress.selector);
        tokenRegistry.addEntry(communityAddress, address(0));
    }

    function test_RevertWhen_EntryAlreadyExists() public {
        vm.startPrank(tokenDeployerAccount);
        tokenRegistry.addEntry(communityAddress, tokenAddress);
        vm.expectRevert(CommunityOwnerTokenRegistry.CommunityOwnerTokenRegistry_EntryAlreadyExists.selector);
        tokenRegistry.addEntry(communityAddress, tokenAddress);
    }

    function test_AddEntry() public {
        vm.startPrank(tokenDeployerAccount);
        vm.expectEmit(true, true, true, true);
        emit AddEntry(communityAddress, tokenAddress);
        tokenRegistry.addEntry(communityAddress, tokenAddress);

        assertEq(tokenRegistry.getEntry(communityAddress), tokenAddress);
    }
}

contract GetEntryTest is CommunityOwnerTokenRegistryTest {
    function setUp() public virtual override {
        CommunityOwnerTokenRegistryTest.setUp();
    }

    function test_ReturnZeroAddressIfEntryDoesNotExist() public {
        assertEq(tokenRegistry.getEntry(makeAddr("someAddress")), address(0));
    }
}
