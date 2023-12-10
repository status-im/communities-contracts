// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";
import { TestERC20Token } from "../contracts/mocks/TestERC20Token.sol";
import { TestERC721Token } from "../contracts/mocks/TestERC721Token.sol";
import { CommunityVault } from "../contracts/CommunityVault.sol";
import { CommunityOwnable } from "../contracts/CommunityOwnable.sol";
import { DeploymentConfig } from "../script/DeploymentConfig.s.sol";
import { DeployOwnerAndMasterToken } from "../script/DeployOwnerAndMasterToken.s.sol";
import { CommunityERC20 } from "../contracts/tokens/CommunityERC20.sol";
import { OwnerToken } from "../contracts/tokens/OwnerToken.sol";
import { MasterToken } from "../contracts/tokens/MasterToken.sol";

contract CommunityVaultTest is Test {
    CommunityVault internal vault;

    address[] internal accounts = new address[](2);
    address internal deployer;

    TestERC20Token internal erc20Token;
    TestERC721Token internal erc721Token;
    CommunityERC20 internal communityERC20Token;
    OwnerToken internal ownerToken;
    MasterToken internal masterToken;

    function setUp() public virtual {
        DeploymentConfig deploymentConfig;
        DeployOwnerAndMasterToken deployment = new DeployOwnerAndMasterToken();
        (ownerToken, masterToken, deploymentConfig) = deployment.run();

        deployer = deploymentConfig.deployer();

        erc20Token = new TestERC20Token();
        erc721Token = new TestERC721Token();

        communityERC20Token = new CommunityERC20(
            "Test",
            "TEST",
            18,
            100,
            "",
            address(ownerToken),
            address(masterToken)
        );

        vault = new CommunityVault(address(ownerToken), address(masterToken));

        accounts[0] = makeAddr("one");
        accounts[1] = makeAddr("two");
    }

    function test_Deployment() public {
        assertEq(vault.ownerToken(), address(ownerToken));
        assertEq(vault.masterToken(), address(masterToken));
    }
}

contract CommunityVaultBaseERC20Test is CommunityVaultTest {
    function setUp() public virtual override {
        CommunityVaultTest.setUp();

        // mint 10 tokens to user
        address user = accounts[0];
        erc20Token.mint(user, 10e18);

        // user transfer 10 tokens to the vault
        vm.prank(user);
        erc20Token.transfer(address(vault), 10e18);
    }
}

contract TransferERC20ByNonAdminTest is CommunityVaultBaseERC20Test {
    function setUp() public virtual override {
        CommunityVaultBaseERC20Test.setUp();
    }

    function test_revertIfCalledByNonAdmin() public {
        assertEq(erc20Token.balanceOf(address(vault)), 10e18);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        vm.prank(accounts[0]);

        vm.expectRevert(CommunityOwnable.CommunityOwnable_NotAuthorized.selector);
        vault.transferERC20(address(erc20Token), accounts, amounts);
    }
}

contract TransferERC20ByAdminTest is CommunityVaultBaseERC20Test {
    function setUp() public virtual override {
        CommunityVaultBaseERC20Test.setUp();
    }

    function test_LengthMismatch() public {
        assertEq(erc20Token.balanceOf(address(vault)), 10e18);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 5e18;

        vm.prank(deployer);
        vm.expectRevert(CommunityVault.CommunityVault_LengthMismatch.selector);
        vault.transferERC20(address(erc20Token), accounts, amounts);
    }

    function test_TransferAmountZero() public {
        assertEq(erc20Token.balanceOf(address(vault)), 10e18);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 5e18;
        amounts[1] = 0;

        vm.prank(deployer);
        vm.expectRevert(CommunityVault.CommunityVault_TransferAmountZero.selector);
        vault.transferERC20(address(erc20Token), accounts, amounts);
    }

    function test_NoRecipients() public {
        assertEq(erc20Token.balanceOf(address(vault)), 10e18);

        uint256[] memory amounts = new uint256[](0);
        address[] memory tmpAccounts = new address[](0);

        vm.prank(deployer);
        vm.expectRevert(CommunityVault.CommunityVault_NoRecipients.selector);
        vault.transferERC20(address(erc20Token), tmpAccounts, amounts);
    }

    function test_AdminCanTransferERC20() public {
        assertEq(erc20Token.balanceOf(address(vault)), 10e18);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 5e18;
        amounts[1] = 5e18;

        vm.prank(deployer);
        vault.transferERC20(address(erc20Token), accounts, amounts);

        assertEq(erc20Token.balanceOf(address(vault)), 0);
    }
}

contract CommunityVaultBaseERC721Test is CommunityVaultTest {
    function setUp() public virtual override {
        CommunityVaultTest.setUp();

        // mint 2 token to user
        address user = accounts[0];
        erc721Token.mint(user);
        erc721Token.mint(user);

        // user transfer 2 tokens to the vault
        vm.startPrank(user);
        erc721Token.transferFrom(user, address(vault), 0);
        erc721Token.transferFrom(user, address(vault), 1);
        vm.stopPrank();
    }
}

contract TransferERC721ByNonAdminTest is CommunityVaultBaseERC721Test {
    function setUp() public virtual override {
        CommunityVaultBaseERC721Test.setUp();
    }

    function test_RevertIfCalledByNonAdmin() public {
        assertEq(erc721Token.balanceOf(address(vault)), 2);
        uint256[] memory ids = new uint256[](2);
        ids[0] = 0;
        ids[1] = 1;

        vm.prank(accounts[0]);
        vm.expectRevert(CommunityOwnable.CommunityOwnable_NotAuthorized.selector);

        vault.transferERC721(address(erc721Token), accounts, ids);
    }
}

contract TransferERC721ByAdminTest is CommunityVaultBaseERC721Test {
    function setUp() public virtual override {
        CommunityVaultBaseERC721Test.setUp();
    }

    function test_LengthMismatch() public {
        assertEq(erc721Token.balanceOf(address(vault)), 2);

        uint256[] memory ids = new uint256[](1);
        ids[0] = 0;

        vm.prank(deployer);
        vm.expectRevert(CommunityVault.CommunityVault_LengthMismatch.selector);
        vault.transferERC721(address(erc721Token), accounts, ids);
    }

    function test_NoRecipients() public {
        assertEq(erc721Token.balanceOf(address(vault)), 2);

        uint256[] memory ids = new uint256[](0);
        address[] memory tmpAccounts = new address[](0);

        vm.prank(deployer);
        vm.expectRevert(CommunityVault.CommunityVault_NoRecipients.selector);
        vault.transferERC721(address(erc721Token), tmpAccounts, ids);
    }

    function test_AdminCanTransferERC721() public {
        assertEq(erc721Token.balanceOf(address(vault)), 2);

        assertEq(erc721Token.ownerOf(0), address(vault));
        assertEq(erc721Token.ownerOf(1), address(vault));

        uint256[] memory ids = new uint256[](2);
        ids[0] = 0;
        ids[1] = 1;

        vm.prank(deployer);
        vault.transferERC721(address(erc721Token), accounts, ids);

        assertEq(erc721Token.balanceOf(address(vault)), 0);
    }
}
