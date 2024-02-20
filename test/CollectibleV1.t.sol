// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";
import { DeployOwnerAndMasterToken } from "../script/DeployOwnerAndMasterToken.s.sol";
import { DeploymentConfig } from "../script/DeploymentConfig.s.sol";
import { CommunityOwnable } from "../contracts/CommunityOwnable.sol";
import { BaseToken } from "../contracts/tokens/BaseToken.sol";
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
            name, symbol, maxSupply, remoteBurnable, transferable, baseURI, address(ownerToken), address(masterToken)
        );

        accounts[0] = makeAddr("one");
        accounts[1] = makeAddr("two");
        accounts[2] = makeAddr("three");
        accounts[3] = makeAddr("four");
    }
}

contract DeploymentTest is CollectibleV1Test {
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
    event StatusMint(address indexed from, address indexed to, uint256 indexed tokenId);

    function setUp() public virtual override {
        CollectibleV1Test.setUp();
    }

    function test_RevertWhen_SenderIsNotOwner() public {
        vm.expectRevert(CommunityOwnable.CommunityOwnable_NotAuthorized.selector);
        collectibleV1.mintTo(accounts);
    }

    function test_RevertWhen_MaxSupplyIsReached() public {
        vm.startPrank(deployer);
        collectibleV1.mintTo(accounts);

        address[] memory otherAddresses = new address[](1);
        otherAddresses[0] = makeAddr("anotherAccount");
        vm.expectRevert(BaseToken.BaseToken_MaxSupplyReached.selector);
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
        for (uint8 i = 0; i < length; i++) {
            vm.expectEmit(true, true, true, true);
            emit StatusMint(address(0), accounts[i], i);
        }
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
        vm.expectRevert(CommunityOwnable.CommunityOwnable_NotAuthorized.selector);
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

contract SafeBatchTransferFromTest is CollectibleV1Test {
    function setUp() public virtual override {
        CollectibleV1Test.setUp();
    }

    function test_RevertWhen_ReceiversAndIdsMismatch() public {
        // ensure sender owns a token
        vm.prank(deployer);
        collectibleV1.mintTo(accounts);

        address[] memory receivers = new address[](1);
        receivers[0] = accounts[1];

        // ids must be of same length as `receivers`
        uint256[] memory ids = new uint256[](2);
        ids[0] = 0;
        ids[1] = 1;

        vm.prank(accounts[0]);
        vm.expectRevert(BaseToken.BaseToken_ReceiversAndIdsMismatch.selector);
        collectibleV1.safeBatchTransferFrom(accounts[0], receivers, ids, "");
    }

    function test_RevertWhen_NotAuthorized() public {
        vm.prank(deployer);
        collectibleV1.mintTo(accounts);

        address[] memory receivers = new address[](1);
        receivers[0] = accounts[3];

        // ids must be of same length as `accounts`
        uint256[] memory ids = new uint256[](1);
        ids[0] = 0;

        // ensure accounts[3] has no ownership or approval of token with id `0`
        assertEq(collectibleV1.ownerOf(ids[0]), accounts[0]);
        assertEq(collectibleV1.isApprovedForAll(accounts[0], receivers[0]), false);

        vm.prank(receivers[0]);
        vm.expectRevert(bytes("ERC721: caller is not token owner or approved"));
        collectibleV1.safeBatchTransferFrom(accounts[0], receivers, ids, "");
    }

    function test_RevertWhen_ReceiverAddressIsZero() public {
        // ensure sender owns a token
        vm.prank(deployer);
        collectibleV1.mintTo(accounts);

        address[] memory receivers = new address[](1);
        receivers[0] = address(0);

        uint256[] memory ids = new uint256[](1);
        ids[0] = 0;

        vm.prank(accounts[0]);
        vm.expectRevert(bytes("ERC721: transfer to the zero address"));
        collectibleV1.safeBatchTransferFrom(accounts[0], receivers, ids, "");
    }

    function test_SafeBatchTransferFrom() public {
        // ensure sender owns a token
        vm.prank(deployer);
        address[] memory sameAddresses = new address[](3);
        sameAddresses[0] = accounts[0];
        sameAddresses[1] = accounts[0];
        sameAddresses[2] = accounts[0];
        collectibleV1.mintTo(sameAddresses);

        address[] memory receivers = new address[](3);
        receivers[0] = accounts[1];
        receivers[1] = accounts[2];
        receivers[2] = accounts[3];

        uint256[] memory ids = new uint256[](3);
        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 2;

        vm.prank(accounts[0]);
        collectibleV1.safeBatchTransferFrom(accounts[0], receivers, ids, "");

        assertEq(collectibleV1.balanceOf(accounts[0]), 0);
        assertEq(collectibleV1.balanceOf(accounts[1]), 1);
        assertEq(collectibleV1.balanceOf(accounts[2]), 1);
        assertEq(collectibleV1.balanceOf(accounts[3]), 1);
    }

    function test_SafeBatchTransferFromToSingleReceiver() public {
        // ensure sender owns a token
        vm.prank(deployer);
        address[] memory sameAddresses = new address[](3);
        sameAddresses[0] = accounts[0];
        sameAddresses[1] = accounts[0];
        sameAddresses[2] = accounts[0];
        collectibleV1.mintTo(sameAddresses);

        address[] memory receivers = new address[](3);
        receivers[0] = accounts[1];
        receivers[1] = accounts[1];
        receivers[2] = accounts[1];

        uint256[] memory ids = new uint256[](3);
        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 2;

        vm.prank(accounts[0]);
        collectibleV1.safeBatchTransferFrom(accounts[0], receivers, ids, "");

        assertEq(collectibleV1.balanceOf(accounts[0]), 0);
        assertEq(collectibleV1.balanceOf(accounts[1]), 3);
    }
}

contract NotTransferableTest is CollectibleV1Test {
    function setUp() public virtual override {
        DeployOwnerAndMasterToken deployment = new DeployOwnerAndMasterToken();
        (OwnerToken ownerToken, MasterToken masterToken, DeploymentConfig deploymentConfig) = deployment.run();
        deployer = deploymentConfig.deployer();

        collectibleV1 = new CollectibleV1(
            name, symbol, maxSupply, remoteBurnable, false, baseURI, address(ownerToken), address(masterToken)
        );

        accounts[0] = makeAddr("one");
        accounts[1] = makeAddr("two");
        accounts[2] = makeAddr("three");
        accounts[3] = makeAddr("four");
    }

    function test_RevertWhen_TokenIsNotTransferable() public {
        // ensure accounts own tokens
        vm.prank(deployer);
        collectibleV1.mintTo(accounts);
        uint256[] memory ids = new uint256[](4);
        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 2;
        ids[3] = 3;

        vm.prank(accounts[0]);
        vm.expectRevert(BaseToken.BaseToken_NotTransferable.selector);
        collectibleV1.safeBatchTransferFrom(accounts[0], accounts, ids, "");
    }
}
