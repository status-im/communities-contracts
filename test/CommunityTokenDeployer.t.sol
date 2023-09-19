// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { DeployContracts } from "../script/DeployContracts.s.sol";
import { DeploymentConfig } from "../script/DeploymentConfig.s.sol";
import { BaseTokenFactory } from "../contracts/factories/BaseTokenFactory.sol";
import { OwnerToken } from "../contracts/tokens/OwnerToken.sol";
import { MasterToken } from "../contracts/tokens/MasterToken.sol";
import { CommunityOwnerTokenRegistry } from "../contracts/CommunityOwnerTokenRegistry.sol";
import { CommunityTokenDeployer } from "../contracts/CommunityTokenDeployer.sol";

contract CommunityTokenDeployerTest is Test {
    DeploymentConfig internal deploymentConfig;

    CommunityTokenDeployer internal tokenDeployer;
    CommunityOwnerTokenRegistry internal tokenRegistry;

    address internal deployer;

    address internal immutable owner = makeAddr("owner");

    address internal communityAddress;
    uint256 internal communityKey;

    function setUp() public virtual {
        DeployContracts deployment = new DeployContracts();
        (tokenDeployer, tokenRegistry,,, deploymentConfig) = deployment.run();
        deployer = deploymentConfig.deployer();
        (communityAddress, communityKey) = makeAddrAndKey("community");
    }

    function test_Deployment() public {
        assertEq(tokenDeployer.deploymentRegistry(), address(tokenRegistry));
        assertEq(tokenDeployer.owner(), deployer);
    }

    function _getOwnerTokenConfig() internal view returns (CommunityTokenDeployer.TokenConfig memory, bytes memory) {
        (
            string memory ownerTokenName,
            string memory ownerTokenSymbol,
            string memory ownerTokenBaseURI,
            bytes memory signerPublicKey
        ) = deploymentConfig.ownerTokenConfig();

        CommunityTokenDeployer.TokenConfig memory ownerTokenConfig =
            CommunityTokenDeployer.TokenConfig(ownerTokenName, ownerTokenSymbol, ownerTokenBaseURI);
        return (ownerTokenConfig, signerPublicKey);
    }

    function _getMasterTokenConfig() internal view returns (CommunityTokenDeployer.TokenConfig memory) {
        (string memory masterTokenName, string memory masterTokenSymbol, string memory masterTokenBaseURI,) =
            deploymentConfig.masterTokenConfig();

        CommunityTokenDeployer.TokenConfig memory masterTokenConfig =
            CommunityTokenDeployer.TokenConfig(masterTokenName, masterTokenSymbol, masterTokenBaseURI);
        return masterTokenConfig;
    }

    function _createDeploymentSignature(
        uint256 _signerKey,
        address _signer,
        address _deployer
    )
        internal
        view
        returns (CommunityTokenDeployer.DeploymentSignature memory)
    {
        bytes32 digest = ECDSA.toTypedDataHash(
            tokenDeployer.DOMAIN_SEPARATOR(),
            keccak256(abi.encode(tokenDeployer.DEPLOYMENT_SIGNATURE_TYPEHASH(), _signer, _deployer))
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_signerKey, digest);
        return CommunityTokenDeployer.DeploymentSignature(_signer, _deployer, v, r, s);
    }
}

contract SetDeploymentRegistryAddressTest is CommunityTokenDeployerTest {
    event DeploymentRegistryAddressChange(address indexed);

    function setUp() public virtual override {
        CommunityTokenDeployerTest.setUp();
    }

    function test_RevertWhen_SenderIsNotOwner() public {
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        tokenDeployer.setDeploymentRegistryAddress(makeAddr("someAddress"));
    }

    function test_RevertWhen_InvalidDeploymentRegistryAddress() public {
        vm.prank(deployer);
        vm.expectRevert(CommunityTokenDeployer.CommunityTokenDeployer_InvalidDeploymentRegistryAddress.selector);
        tokenDeployer.setDeploymentRegistryAddress(address(0));
    }

    function test_SetDeploymentRegistryAddress() public {
        address newAddress = makeAddr("newAddress");
        vm.prank(deployer);
        vm.expectEmit(true, true, true, true);
        emit DeploymentRegistryAddressChange(newAddress);
        tokenDeployer.setDeploymentRegistryAddress(newAddress);

        assertEq(tokenDeployer.deploymentRegistry(), newAddress);
    }
}

contract SetOwnerTokenFactoryAddressTest is CommunityTokenDeployerTest {
    event OwnerTokenFactoryAddressChange(address indexed);

    function setUp() public virtual override {
        CommunityTokenDeployerTest.setUp();
    }

    function test_RevertWhen_SenderIsNotOwner() public {
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        tokenDeployer.setOwnerTokenFactoryAddress(makeAddr("someAddress"));
    }

    function test_RevertWhen_InvalidTokenFactoryAddress() public {
        vm.prank(deployer);
        vm.expectRevert(CommunityTokenDeployer.CommunityTokenDeployer_InvalidTokenFactoryAddress.selector);
        tokenDeployer.setOwnerTokenFactoryAddress(address(0));
    }

    function test_SetOwnerTokenFactoryAddress() public {
        address newAddress = makeAddr("newAddress");
        vm.prank(deployer);
        vm.expectEmit(true, true, true, true);
        emit OwnerTokenFactoryAddressChange(newAddress);
        tokenDeployer.setOwnerTokenFactoryAddress(newAddress);

        assertEq(tokenDeployer.ownerTokenFactory(), newAddress);
    }
}

contract SetMasterTokenFactoryAddressTest is CommunityTokenDeployerTest {
    event MasterTokenFactoryAddressChange(address indexed);

    function setUp() public virtual override {
        CommunityTokenDeployerTest.setUp();
    }

    function test_RevertWhen_SenderIsNotOwner() public {
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        tokenDeployer.setMasterTokenFactoryAddress(makeAddr("someAddress"));
    }

    function test_RevertWhen_InvalidTokenFactoryAddress() public {
        vm.prank(deployer);
        vm.expectRevert(CommunityTokenDeployer.CommunityTokenDeployer_InvalidTokenFactoryAddress.selector);
        tokenDeployer.setMasterTokenFactoryAddress(address(0));
    }

    function test_SetOwnerTokenFactoryAddress() public {
        address newAddress = makeAddr("newAddress");
        vm.prank(deployer);
        vm.expectEmit(true, true, true, true);
        emit MasterTokenFactoryAddressChange(newAddress);
        tokenDeployer.setMasterTokenFactoryAddress(newAddress);

        assertEq(tokenDeployer.masterTokenFactory(), newAddress);
    }
}

contract DeployTest is CommunityTokenDeployerTest {
    function setUp() public virtual override {
        CommunityTokenDeployerTest.setUp();
    }

    function test_RevertWhen_InvalidDeployerAddress() public {
        (CommunityTokenDeployer.TokenConfig memory ownerTokenConfig, bytes memory signerPublicKey) =
            _getOwnerTokenConfig();
        CommunityTokenDeployer.TokenConfig memory masterTokenConfig = _getMasterTokenConfig();
        CommunityTokenDeployer.DeploymentSignature memory signature =
            _createDeploymentSignature(communityKey, communityAddress, makeAddr("someone else"));
        vm.prank(owner);
        vm.expectRevert(CommunityTokenDeployer.CommunityTokenDeployer_InvalidDeployerAddress.selector);
        tokenDeployer.deploy(ownerTokenConfig, masterTokenConfig, signature, signerPublicKey);
    }

    function test_RevertWhen_InvalidDeploymentSignature() public {
        (CommunityTokenDeployer.TokenConfig memory ownerTokenConfig, bytes memory signerPublicKey) =
            _getOwnerTokenConfig();
        CommunityTokenDeployer.TokenConfig memory masterTokenConfig = _getMasterTokenConfig();
        CommunityTokenDeployer.DeploymentSignature memory signature =
            _createDeploymentSignature(communityKey, makeAddr("invalid address"), owner);
        vm.prank(owner);
        vm.expectRevert(CommunityTokenDeployer.CommunityTokenDeployer_InvalidDeploymentSignature.selector);
        tokenDeployer.deploy(ownerTokenConfig, masterTokenConfig, signature, signerPublicKey);
    }

    function test_RevertWhen_InvalidTokenMetadata() public {
        (, bytes memory signerPublicKey) = _getOwnerTokenConfig();
        CommunityTokenDeployer.TokenConfig memory ownerTokenConfig = CommunityTokenDeployer.TokenConfig("", "", "");
        CommunityTokenDeployer.TokenConfig memory masterTokenConfig = CommunityTokenDeployer.TokenConfig("", "", "");
        CommunityTokenDeployer.DeploymentSignature memory signature =
            _createDeploymentSignature(communityKey, communityAddress, owner);

        vm.prank(owner);
        vm.expectRevert(BaseTokenFactory.BaseTokenFactory_InvalidTokenMetadata.selector);
        tokenDeployer.deploy(ownerTokenConfig, masterTokenConfig, signature, signerPublicKey);

        // fill `masterTokenConfig` with data
        masterTokenConfig = _getMasterTokenConfig();

        vm.prank(owner);
        vm.expectRevert(BaseTokenFactory.BaseTokenFactory_InvalidTokenMetadata.selector);
        tokenDeployer.deploy(ownerTokenConfig, masterTokenConfig, signature, signerPublicKey);

        // fill `ownerTokenConfig` with data and reset `masterTokenConfig`
        (ownerTokenConfig,) = _getOwnerTokenConfig();
        masterTokenConfig = CommunityTokenDeployer.TokenConfig("", "", "");

        vm.prank(owner);
        vm.expectRevert(BaseTokenFactory.BaseTokenFactory_InvalidTokenMetadata.selector);
        tokenDeployer.deploy(ownerTokenConfig, masterTokenConfig, signature, signerPublicKey);
    }

    function test_RevertWhen_InvalidSignerPublicKey() public {
        (CommunityTokenDeployer.TokenConfig memory ownerTokenConfig,) = _getOwnerTokenConfig();
        CommunityTokenDeployer.TokenConfig memory masterTokenConfig = _getMasterTokenConfig();
        CommunityTokenDeployer.DeploymentSignature memory signature =
            _createDeploymentSignature(communityKey, communityAddress, owner);

        vm.prank(owner);
        vm.expectRevert(CommunityTokenDeployer.CommunityTokenDeployer_InvalidSignerKeyOrCommunityAddress.selector);
        tokenDeployer.deploy(ownerTokenConfig, masterTokenConfig, signature, bytes(""));
    }

    function test_RevertWhen_InvalidCommunityAddress() public {
        (CommunityTokenDeployer.TokenConfig memory ownerTokenConfig, bytes memory signerPublicKey) =
            _getOwnerTokenConfig();
        CommunityTokenDeployer.TokenConfig memory masterTokenConfig = _getMasterTokenConfig();
        CommunityTokenDeployer.DeploymentSignature memory signature =
            _createDeploymentSignature(communityKey, address(0), owner);

        vm.prank(owner);
        vm.expectRevert(CommunityTokenDeployer.CommunityTokenDeployer_InvalidSignerKeyOrCommunityAddress.selector);
        tokenDeployer.deploy(ownerTokenConfig, masterTokenConfig, signature, signerPublicKey);
    }

    function test_RevertWhen_AlreadyDeployed() public {
        (CommunityTokenDeployer.TokenConfig memory ownerTokenConfig, bytes memory signerPublicKey) =
            _getOwnerTokenConfig();
        CommunityTokenDeployer.TokenConfig memory masterTokenConfig = _getMasterTokenConfig();
        CommunityTokenDeployer.DeploymentSignature memory signature =
            _createDeploymentSignature(communityKey, communityAddress, owner);

        vm.startPrank(owner);
        tokenDeployer.deploy(ownerTokenConfig, masterTokenConfig, signature, signerPublicKey);

        vm.expectRevert(CommunityTokenDeployer.CommunityTokenDeployer_AlreadyDeployed.selector);
        tokenDeployer.deploy(ownerTokenConfig, masterTokenConfig, signature, signerPublicKey);
    }

    function test_Deploy() public {
        (CommunityTokenDeployer.TokenConfig memory ownerTokenConfig, bytes memory signerPublicKey) =
            _getOwnerTokenConfig();
        CommunityTokenDeployer.TokenConfig memory masterTokenConfig = _getMasterTokenConfig();
        CommunityTokenDeployer.DeploymentSignature memory signature =
            _createDeploymentSignature(communityKey, communityAddress, owner);

        vm.prank(owner);
        (address ownerTokenAddress, address masterTokenAddress) =
            tokenDeployer.deploy(ownerTokenConfig, masterTokenConfig, signature, signerPublicKey);

        assertEq(ownerTokenAddress, tokenRegistry.getEntry(communityAddress));
        assertEq(OwnerToken(ownerTokenAddress).balanceOf(owner), 1);

        MasterToken masterToken = MasterToken(masterTokenAddress);

        assertEq(masterToken.ownerToken(), ownerTokenAddress);
        assertEq(masterToken.balanceOf(owner), 0);
        assertEq(masterToken.remoteBurnable(), true);
        assertEq(masterToken.transferable(), false);
    }
}
