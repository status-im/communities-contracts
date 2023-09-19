// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";
import { DeployOwnerAndMasterToken } from "../script/DeployOwnerAndMasterToken.s.sol";
import { DeploymentConfig } from "../script/DeploymentConfig.s.sol";
import { OwnerToken } from "../contracts/tokens/OwnerToken.sol";
import { MasterToken } from "../contracts/tokens/MasterToken.sol";
import { CollectibleV1 } from "../contracts/tokens/CollectibleV1.sol";

contract CollectibleV1Test is Test {
    CollectibleV1 internal collectibleV1;

    address internal deployer;
    address[] internal accounts = new address[](4);

    string internal name = "Test";
    string internal symbol = "TEST";
    string internal baseURI = "http://local.dev";
    uint256 internal maxSupply = 4;
    bool internal remoteBurnable = true;
    bool internal transferable = true;

    function setUp() public virtual {
        DeployOwnerAndMasterToken deployment = new DeployOwnerAndMasterToken();
        (OwnerToken ownerToken, MasterToken masterToken, DeploymentConfig deploymentConfig) = deployment.run();
        deployer = deploymentConfig.deployer();

        collectibleV1 = new CollectibleV1(
          name,
          symbol,
          maxSupply,
          remoteBurnable, 
          transferable,
          baseURI,
          address(ownerToken),
          address(masterToken)
        );

        accounts[0] = makeAddr("one");
        accounts[1] = makeAddr("two");
        accounts[2] = makeAddr("three");
        accounts[3] = makeAddr("four");
    }

    function test_Deployment() public {
        assertEq(collectibleV1.name(), name);
        assertEq(collectibleV1.symbol(), symbol);
        assertEq(collectibleV1.maxSupply(), maxSupply);
        assertEq(collectibleV1.remoteBurnable(), remoteBurnable);
        assertEq(collectibleV1.transferable(), transferable);
        assertEq(collectibleV1.baseTokenURI(), baseURI);
    }
}

contract MintToTest is CollectibleV1Test {
    function setUp() public virtual override {
        CollectibleV1Test.setUp();
    }

    function test_RevertWhen_SenderIsNotOwner() public {
        vm.expectRevert(bytes("Not authorized"));
        collectibleV1.mintTo(accounts);
    }

    function test_RevertWhen_MaxSupplyIsReached() public {
        vm.startPrank(deployer);
        collectibleV1.mintTo(accounts);

        address[] memory otherAddresses = new address[](1);
        otherAddresses[0] = makeAddr("anotherAccount");
        vm.expectRevert(bytes("MAX_SUPPLY_REACHED"));
        collectibleV1.mintTo(otherAddresses);

        assertEq(collectibleV1.maxSupply(), maxSupply);
        assertEq(collectibleV1.totalSupply(), maxSupply);
    }

    function test_MintTo() public {
        uint256 length = accounts.length;
        for (uint8 i = 0; i < length; i++) {
            assertEq(collectibleV1.balanceOf(accounts[i]), 0);
        }
        vm.prank(deployer);
        collectibleV1.mintTo(accounts);
        for (uint8 i = 0; i < length; i++) {
            assertEq(collectibleV1.balanceOf(accounts[i]), 1);
        }
    }
}

contract RemoteBurnTest is CollectibleV1Test {
    function setUp() public virtual override {
        CollectibleV1Test.setUp();
    }

    function test_RevertWhen_SenderIsNotOwner() public {
        uint256[] memory ids = new uint256[](1);
        ids[0] = 0;
        vm.expectRevert(bytes("Not authorized"));
        collectibleV1.remoteBurn(ids);
    }

    function test_RemoteBurn() public {
        vm.startPrank(deployer);
        collectibleV1.mintTo(accounts);

        assertEq(collectibleV1.totalSupply(), maxSupply);

        uint256[] memory ids = new uint256[](1);
        ids[0] = 0;
        collectibleV1.remoteBurn(ids);

        assertEq(collectibleV1.balanceOf(accounts[0]), 0);
        assertEq(collectibleV1.totalSupply(), maxSupply - 1);
    }
}