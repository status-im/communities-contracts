// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";
import { CommunityERC20 } from "../contracts/tokens/CommunityERC20.sol";
import { DeploymentConfig } from "../script/DeploymentConfig.s.sol";
import { DeployOwnerAndMasterToken } from "../script/DeployOwnerAndMasterToken.s.sol";
import { OwnerToken } from "../contracts/tokens/OwnerToken.sol";
import { MasterToken } from "../contracts/tokens/MasterToken.sol";
import { CommunityOwnable } from "../contracts/CommunityOwnable.sol";

contract CommunityERC20Test is Test {
    CommunityERC20 internal communityToken;

    address[] internal accounts = new address[](4);
    address internal deployer;

    string internal name = "Test";
    string internal symbol = "TEST";
    string internal baseURI = "http://local.dev";
    uint256 internal maxSupply = 100;
    uint8 internal decimals = 18;

    function setUp() public virtual {
        DeployOwnerAndMasterToken deployment = new DeployOwnerAndMasterToken();
        (OwnerToken ownerToken, MasterToken masterToken, DeploymentConfig deploymentConfig) = deployment.run();

        deployer = deploymentConfig.deployer();

        communityToken = new CommunityERC20(
            name,
            symbol,
            decimals,
            maxSupply,
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
        assertEq(communityToken.name(), name);
        assertEq(communityToken.symbol(), symbol);
        assertEq(communityToken.maxSupply(), maxSupply);
        assertEq(communityToken.decimals(), decimals);
        assertEq(communityToken.baseTokenURI(), baseURI);
    }
}

contract SetMaxSupplyTest is CommunityERC20Test {
    function setUp() public virtual override {
        CommunityERC20Test.setUp();
    }

    function test_RevertWhen_SenderIsNotOwner() public {
        vm.prank(makeAddr("notOwner"));
        vm.expectRevert(CommunityOwnable.CommunityOwnable_NotAuthorized.selector);
        communityToken.setMaxSupply(1000);
    }

    function test_RevertWhen_MaxSupplyLowerThanTotalSupply() public {
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 10;
        amounts[1] = 15;
        amounts[2] = 5;
        amounts[3] = 20;

        vm.startPrank(deployer);

        communityToken.mintTo(accounts, amounts); // totalSupply is now 50
        vm.expectRevert(CommunityERC20.CommunityERC20_MaxSupplyLowerThanTotalSupply.selector);
        communityToken.setMaxSupply(40);

        vm.stopPrank();
    }

    function test_SetMaxSupply() public {
        vm.prank(deployer);
        communityToken.setMaxSupply(1000);
        assertEq(communityToken.maxSupply(), 1000);
    }
}

contract MintToTest is CommunityERC20Test {
    event StatusMint(address indexed from, address indexed to, uint256 indexed amount);

    function setUp() public virtual override {
        CommunityERC20Test.setUp();
    }

    function test_RevertWhen_AddressesAndAmountsAreNotEqualLength() public {
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10;
        amounts[1] = 15;
        amounts[2] = 5;

        vm.expectRevert(CommunityERC20.CommunityERC20_MismatchingAddressesAndAmountsLengths.selector);
        vm.prank(deployer);
        communityToken.mintTo(accounts, amounts);
    }

    function test_RevertWhen_MaxSupplyReached() public {
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 50;
        amounts[1] = 25;
        amounts[2] = 25;
        amounts[3] = 1; // this should exceed max supply

        vm.expectRevert(CommunityERC20.CommunityERC20_MaxSupplyReached.selector);
        vm.prank(deployer);
        communityToken.mintTo(accounts, amounts);
    }

    function test_MintTo() public {
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 50;
        amounts[1] = 25;
        amounts[2] = 20;
        amounts[3] = 5;

        vm.startPrank(deployer);
        for (uint8 i = 0; i < accounts.length; i++) {
            vm.expectEmit(true, true, true, true);
            emit StatusMint(address(0), accounts[i], amounts[i]);
        }
        communityToken.mintTo(accounts, amounts);

        assertEq(communityToken.balanceOf(accounts[0]), 50);
        assertEq(communityToken.balanceOf(accounts[1]), 25);
        assertEq(communityToken.balanceOf(accounts[2]), 20);
        assertEq(communityToken.balanceOf(accounts[3]), 5);
    }
}
