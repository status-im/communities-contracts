// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";
import { DeployOwnerToken } from "../script/DeployOwnerToken.s.sol";
import { DeploymentConfig } from "../script/DeploymentConfig.s.sol";
import { OwnerToken } from "../contracts/OwnerToken.sol";
import { MasterToken } from "../contracts/MasterToken.sol";

contract OwnerTokenTest is Test {
    OwnerToken internal ownerToken;
    MasterToken internal masterToken;
    DeploymentConfig internal deploymentConfig;
    address internal deployer;

    function setUp() public virtual {
        DeployOwnerToken deployment = new DeployOwnerToken();
        (ownerToken, masterToken, deploymentConfig) = deployment.run();
        deployer = deploymentConfig.deployer();
    }

    function test_Deployment() public {
        DeploymentConfig.TokenConfig memory ownerTokenConfig = deploymentConfig.getOwnerTokenConfig();
        DeploymentConfig.TokenConfig memory masterTokenConfig = deploymentConfig.getMasterTokenConfig();
        assertEq(ownerToken.name(), ownerTokenConfig.name);
        assertEq(ownerToken.symbol(), ownerTokenConfig.symbol);
        assertEq(ownerToken.baseTokenURI(), ownerTokenConfig.baseURI);
        assertEq(ownerToken.signerPublicKey(), ownerTokenConfig.signerPublicKey);

        assertEq(ownerToken.remoteBurnable(), false);
        assertEq(ownerToken.transferable(), true);

        assertEq(masterToken.name(), masterTokenConfig.name);
        assertEq(masterToken.symbol(), masterTokenConfig.symbol);
        assertEq(masterToken.baseTokenURI(), masterTokenConfig.baseURI);
    }
}

contract SetMaxSupplyTest is OwnerTokenTest {
    function setUp() public virtual override {
        OwnerTokenTest.setUp();
    }

    function test_RevertWhen_SenderIsNotOwner() public {
        vm.expectRevert(bytes("Not authorized"));
        ownerToken.setMaxSupply(1000);
    }

    function test_RevertWhen_CalledBecauseMaxSupplyIsLocked() public {
        vm.startPrank(deployer);
        vm.expectRevert(bytes("max supply locked"));
        ownerToken.setMaxSupply(1000);
    }
}

contract SetSignerPublicKeyTest is OwnerTokenTest {
    function setUp() public virtual override {
        OwnerTokenTest.setUp();
    }

    function test_RevertWhen_SenderIsNotOwner() public {
        vm.expectRevert(bytes("Not authorized"));
        ownerToken.setSignerPublicKey(bytes("some key"));
    }

    function test_SetSignerPublicKey() public {
        vm.startPrank(deployer);
        ownerToken.setSignerPublicKey(bytes("some key"));

        assertEq(ownerToken.signerPublicKey(), bytes("some key"));
    }
}

contract MintToTest is OwnerTokenTest {
    function setUp() public virtual override {
        OwnerTokenTest.setUp();
    }

    function test_RevertWhen_MaxSupplyIsReached() public {
        address[] memory accounts = new address[](1);
        accounts[0] = makeAddr("anotherAccount");

        vm.startPrank(deployer);
        vm.expectRevert(bytes("MAX_SUPPLY_REACHED"));
        ownerToken.mintTo(accounts);
    }
}

contract RemoteBurnTest is OwnerTokenTest {
    function setUp() public virtual override {
        OwnerTokenTest.setUp();
    }

    function test_RevertWhen_RemoteBurn() public {
        vm.startPrank(deployer);
        vm.expectRevert(bytes("NOT_REMOTE_BURNABLE"));
        uint256[] memory ids = new uint256[](1);
        ids[0] = 0;
        ownerToken.remoteBurn(ids);
    }
}
