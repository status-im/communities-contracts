// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";
import { DeployContracts } from "../script/DeployContracts.s.sol";
import { DeploymentConfig } from "../script/DeploymentConfig.s.sol";
import { BaseTokenFactory } from "../contracts/factories/BaseTokenFactory.sol";
import { CommunityMasterTokenFactory } from "../contracts/factories/CommunityMasterTokenFactory.sol";
import { MasterToken } from "../contracts/tokens/MasterToken.sol";
import { CommunityTokenDeployer } from "../contracts/CommunityTokenDeployer.sol";

contract CommunityMasterTokenFactoryTest is Test {
    DeploymentConfig internal deploymentConfig;

    address internal deployer;

    CommunityTokenDeployer internal tokenDeployer;

    CommunityMasterTokenFactory internal masterTokenFactory;

    function setUp() public virtual {
        DeployContracts deployment = new DeployContracts();
        (tokenDeployer,,, masterTokenFactory, deploymentConfig) = deployment.run();
        deployer = deploymentConfig.deployer();
    }
}

contract DeploymentTest is CommunityMasterTokenFactoryTest {
    function setUp() public virtual override {
        CommunityMasterTokenFactoryTest.setUp();
    }

    function test_Deployment() public {
        assertEq(masterTokenFactory.owner(), deployer);
        assertEq(masterTokenFactory.tokenDeployer(), address(tokenDeployer));
    }
}

contract SetTokenDeployerAddressTest is CommunityMasterTokenFactoryTest {
    event TokenDeployerAddressChange(address indexed);

    function setUp() public virtual override {
        CommunityMasterTokenFactoryTest.setUp();
    }

    function test_RevertWhen_SenderIsNotOwner() public {
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        masterTokenFactory.setTokenDeployerAddress(makeAddr("something"));
    }

    function test_RevertWhen_InvalidTokenDeployerAddress() public {
        vm.prank(deployer);
        vm.expectRevert(BaseTokenFactory.BaseTokenFactory_InvalidTokenDeployerAddress.selector);
        masterTokenFactory.setTokenDeployerAddress(address(0));
    }

    function test_SetTokenDeployerAddress() public {
        address someAddress = makeAddr("someAddress");
        vm.prank(deployer);
        vm.expectEmit(true, true, true, true);
        emit TokenDeployerAddressChange(someAddress);
        masterTokenFactory.setTokenDeployerAddress(someAddress);
        assertEq(masterTokenFactory.tokenDeployer(), someAddress);
    }
}

contract CreateTest is CommunityMasterTokenFactoryTest {
    event CreateToken(address indexed);

    function setUp() public virtual override {
        CommunityMasterTokenFactoryTest.setUp();
    }

    function test_RevertWhen_SenderIsNotTokenDeployer() public {
        string memory name = "TestToken";
        string memory symbol = "TEST";
        string memory baseURI = "http://test.dev";
        address ownerToken = makeAddr("ownerToken");
        bytes memory signerPublicKey = bytes("");

        vm.prank(makeAddr("notTokenDeployer"));
        vm.expectRevert(BaseTokenFactory.BaseTokenFactory_NotAuthorized.selector);
        masterTokenFactory.create(name, symbol, baseURI, ownerToken, signerPublicKey);
    }

    function test_RevertWhen_InvalidTokenMetadata() public {
        string memory name = "";
        string memory symbol = "";
        string memory baseURI = "";
        address ownerToken = makeAddr("ownerToken");
        bytes memory signerPublicKey = bytes("");

        vm.startPrank(address(tokenDeployer));
        vm.expectRevert(BaseTokenFactory.BaseTokenFactory_InvalidTokenMetadata.selector);
        masterTokenFactory.create(name, symbol, baseURI, ownerToken, signerPublicKey);

        baseURI = "http://test.dev";
        vm.expectRevert(BaseTokenFactory.BaseTokenFactory_InvalidTokenMetadata.selector);
        masterTokenFactory.create(name, symbol, baseURI, ownerToken, signerPublicKey);

        symbol = "TEST";
        vm.expectRevert(BaseTokenFactory.BaseTokenFactory_InvalidTokenMetadata.selector);
        masterTokenFactory.create(name, symbol, baseURI, ownerToken, signerPublicKey);
    }

    function test_RevertWhen_InvalidOwnerTokenAddress() public {
        string memory name = "TestToken";
        string memory symbol = "TEST";
        string memory baseURI = "http://test.dev";
        address ownerToken = address(0);
        bytes memory signerPublicKey = bytes("");

        vm.prank(address(tokenDeployer));
        vm.expectRevert(CommunityMasterTokenFactory.CommunityMasterTokenFactory_InvalidOwnerTokenAddress.selector);
        masterTokenFactory.create(name, symbol, baseURI, ownerToken, signerPublicKey);
    }

    function test_Create() public {
        string memory name = "TestToken";
        string memory symbol = "TEST";
        string memory baseURI = "http://test.dev";
        address ownerToken = makeAddr("ownerToken");
        bytes memory signerPublicKey = bytes("some public key");

        vm.prank(address(tokenDeployer));
        vm.expectEmit(false, false, false, false);
        emit CreateToken(makeAddr("some address"));
        address masterTokenAddress = masterTokenFactory.create(name, symbol, baseURI, ownerToken, signerPublicKey);

        assertEq(MasterToken(masterTokenAddress).totalSupply(), 0);
        assertEq(MasterToken(masterTokenAddress).maxSupply(), type(uint256).max);
        assertEq(MasterToken(masterTokenAddress).transferable(), false);
        assertEq(MasterToken(masterTokenAddress).remoteBurnable(), true);
        assertEq(MasterToken(masterTokenAddress).ownerToken(), ownerToken);
    }
}
