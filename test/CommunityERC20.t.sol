// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";
import { CommunityERC20 } from "../contracts/tokens/CommunityERC20.sol";

contract CommunityERC20Test is Test {
    CommunityERC20 internal communityToken;

    address[] internal accounts = new address[](4);

    string internal name = "Test";
    string internal symbol = "TEST";
    uint256 internal maxSupply = 100;
    uint8 internal decimals = 18;

    function setUp() public virtual {
        communityToken = new CommunityERC20(name, symbol, decimals, maxSupply);

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
    }
}

contract SetMaxSupplyTest is CommunityERC20Test {
    function setUp() public virtual override {
        CommunityERC20Test.setUp();
    }

    function test_RevertWhen_SenderIsNotOwner() public {
        vm.prank(makeAddr("notOwner"));
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        communityToken.setMaxSupply(1000);
    }

    function test_RevertWhen_MaxSupplyLowerThanTotalSupply() public {
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 10;
        amounts[1] = 15;
        amounts[2] = 5;
        amounts[3] = 20;
        communityToken.mintTo(accounts, amounts); // totalSupply is now 50
        vm.expectRevert(bytes("MAX_SUPPLY_LOWER_THAN_TOTAL_SUPPLY"));
        communityToken.setMaxSupply(40);
    }

    function test_SetMaxSupply() public {
        communityToken.setMaxSupply(1000);
        assertEq(communityToken.maxSupply(), 1000);
    }
}

contract MintToTest is CommunityERC20Test {
    function setUp() public virtual override {
        CommunityERC20Test.setUp();
    }

    function test_RevertWhen_AddressesAndAmountsAreNotEqualLength() public {
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10;
        amounts[1] = 15;
        amounts[2] = 5;

        vm.expectRevert(bytes("WRONG_LENGTHS"));
        communityToken.mintTo(accounts, amounts);
    }

    function test_RevertWhen_MaxSupplyReached() public {
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 50;
        amounts[1] = 25;
        amounts[2] = 25;
        amounts[3] = 1; // this should exceed max supply

        vm.expectRevert(bytes("MAX_SUPPLY_REACHED"));
        communityToken.mintTo(accounts, amounts);
    }
}
