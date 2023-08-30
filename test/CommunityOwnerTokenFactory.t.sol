// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";
import { DeployContracts } from "../script/DeployContracts.s.sol";
import { DeploymentConfig } from "../script/DeploymentConfig.s.sol";
import { BaseTokenFactory } from "../contracts/factories/BaseTokenFactory.sol";
import { CommunityOwnerTokenFactory } from "../contracts/factories/CommunityOwnerTokenFactory.sol";
import { OwnerToken } from "../contracts/tokens/OwnerToken.sol";
import { CommunityTokenDeployer } from "../contracts/CommunityTokenDeployer.sol";

contract CommunityOwnerTokenFactoryTest is Test {
    DeploymentConfig internal deploymentConfig;

    address internal deployer;

    CommunityTokenDeployer internal tokenDeployer;

    CommunityOwnerTokenFactory internal ownerTokenFactory;

    function setUp() public virtual {
        DeployContracts deployment = new DeployContracts();
        (tokenDeployer,, ownerTokenFactory,, deploymentConfig) = deployment.run();
        deployer = deploymentConfig.deployer();
    }
}

contract DeploymentTest is CommunityOwnerTokenFactoryTest {
    function setUp() public virtual override {
        CommunityOwnerTokenFactoryTest.setUp();
    }

    function test_Deployment() public {
        assertEq(ownerTokenFactory.owner(), deployer);
        assertEq(ownerTokenFactory.tokenDeployer(), address(tokenDeployer));
    }
}

contract SetTokenDeployerAddressTest is CommunityOwnerTokenFactoryTest {
    event TokenDeployerAddressChange(address indexed);

    function setUp() public virtual override {
        CommunityOwnerTokenFactoryTest.setUp();
    }

    function test_RevertWhen_SenderIsNotOwner() public {
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        ownerTokenFactory.setTokenDeployerAddress(makeAddr("something"));
    }

    function test_RevertWhen_InvalidTokenDeployerAddress() public {
        vm.prank(deployer);
        vm.expectRevert(BaseTokenFactory.BaseTokenFactory_InvalidTokenDeployerAddress.selector);
        ownerTokenFactory.setTokenDeployerAddress(address(0));
    }

    function test_SetTokenDeployerAddress() public {
        address someAddress = makeAddr("someAddress");
        vm.prank(deployer);
        vm.expectEmit(true, true, true, true);
        emit TokenDeployerAddressChange(someAddress);
        ownerTokenFactory.setTokenDeployerAddress(someAddress);
        assertEq(ownerTokenFactory.tokenDeployer(), someAddress);
    }
}

contract CreateTest is CommunityOwnerTokenFactoryTest {
    event CreateToken(address indexed);

    function setUp() public virtual override {
        CommunityOwnerTokenFactoryTest.setUp();
    }

    function test_RevertWhen_SenderIsNotTokenDeployer() public {
        string memory name = "TestToken";
        string memory symbol = "TEST";
        string memory baseURI = "http://test.dev";
        address receiver = makeAddr("receiver");
        bytes memory signerPublicKey = bytes("some public key");

        vm.prank(makeAddr("notTokenDeployer"));
        vm.expectRevert(BaseTokenFactory.BaseTokenFactory_NotAuthorized.selector);
        ownerTokenFactory.create(name, symbol, baseURI, receiver, signerPublicKey);
    }

    function test_RevertWhen_InvalidTokenMetadata() public {
        string memory name = "";
        string memory symbol = "";
        string memory baseURI = "";
        address receiver = makeAddr("receiver");
        bytes memory signerPublicKey = bytes("some public key");

        vm.startPrank(address(tokenDeployer));
        vm.expectRevert(BaseTokenFactory.BaseTokenFactory_InvalidTokenMetadata.selector);
        ownerTokenFactory.create(name, symbol, baseURI, receiver, signerPublicKey);

        baseURI = "http://test.dev";
        vm.expectRevert(BaseTokenFactory.BaseTokenFactory_InvalidTokenMetadata.selector);
        ownerTokenFactory.create(name, symbol, baseURI, receiver, signerPublicKey);

        symbol = "TEST";
        vm.expectRevert(BaseTokenFactory.BaseTokenFactory_InvalidTokenMetadata.selector);
        ownerTokenFactory.create(name, symbol, baseURI, receiver, signerPublicKey);
    }

    function test_RevertWhen_InvalidReceiverAddress() public {
        string memory name = "TestToken";
        string memory symbol = "TEST";
        string memory baseURI = "http://test.dev";
        address receiver = address(0);
        bytes memory signerPublicKey = bytes("some public key");

        vm.prank(address(tokenDeployer));
        vm.expectRevert(CommunityOwnerTokenFactory.CommunityOwnerTokenFactory_InvalidReceiverAddress.selector);
        ownerTokenFactory.create(name, symbol, baseURI, receiver, signerPublicKey);
    }

    function test_RevertWhen_InvalidSignerPublicKey() public {
        string memory name = "TestToken";
        string memory symbol = "TEST";
        string memory baseURI = "http://test.dev";
        address receiver = makeAddr("receiver");
        bytes memory signerPublicKey = bytes("");

        vm.prank(address(tokenDeployer));
        vm.expectRevert(CommunityOwnerTokenFactory.CommunityOwnerTokenFactory_InvalidSignerPublicKey.selector);
        ownerTokenFactory.create(name, symbol, baseURI, receiver, signerPublicKey);
    }

    function test_Create() public {
        string memory name = "TestToken";
        string memory symbol = "TEST";
        string memory baseURI = "http://test.dev";
        address receiver = makeAddr("receiver");
        bytes memory signerPublicKey = bytes("some public key");

        vm.prank(address(tokenDeployer));
        vm.expectEmit(false, false, false, false);
        emit CreateToken(makeAddr("some address"));
        address ownerTokenAddress = ownerTokenFactory.create(name, symbol, baseURI, receiver, signerPublicKey);

        assertEq(OwnerToken(ownerTokenAddress).totalSupply(), 1);
        assertEq(OwnerToken(ownerTokenAddress).maxSupply(), 1);
        assertEq(OwnerToken(ownerTokenAddress).balanceOf(receiver), 1);
    }
}
