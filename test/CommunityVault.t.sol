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

        communityERC20Token = new CommunityERC20("Test", "TST", 18, 100, "", address(ownerToken), address(masterToken));

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
        erc20Token.mint(accounts[0], 10e18);
    }
}

contract TransferERC20ByNonAdminTest is CommunityVaultBaseERC20Test {
    function setUp() public virtual override {
        CommunityVaultBaseERC20Test.setUp();
    }

    function test_revertIfCalledByNonAdmin() public {
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        vm.prank(accounts[0]);

        vm.expectRevert(CommunityOwnable.CommunityOwnable_NotAuthorized.selector);
        vault.transferERC20(address(erc20Token), accounts, amounts);
    }
}

contract TransferERC20ByAdminTest is CommunityVaultBaseERC20Test {
    uint256 private depositAmount = 10e18;

    function setUp() public virtual override {
        CommunityVaultBaseERC20Test.setUp();

        vm.startPrank(accounts[0]);
        erc20Token.approve(address(vault), depositAmount);
        vault.depositERC20(address(erc20Token), depositAmount);
        vm.stopPrank();
    }

    function test_LengthMismatch() public {
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 5e18;

        vm.prank(deployer);
        vm.expectRevert(CommunityVault.CommunityVault_LengthMismatch.selector);
        vault.transferERC20(address(erc20Token), accounts, amounts);
    }

    function test_TransferAmountZero() public {
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 5e18;
        amounts[1] = 0;

        vm.prank(deployer);
        vm.expectRevert(CommunityVault.CommunityVault_TransferAmountZero.selector);
        vault.transferERC20(address(erc20Token), accounts, amounts);
    }

    function test_NoRecipients() public {
        uint256[] memory amounts = new uint256[](0);
        address[] memory tmpAccounts = new address[](0);

        vm.prank(deployer);
        vm.expectRevert(CommunityVault.CommunityVault_NoRecipients.selector);
        vault.transferERC20(address(erc20Token), tmpAccounts, amounts);
    }

    function test_AdminCanTransferERC20() public {
        assertEq(erc20Token.balanceOf(address(vault)), 10e18);
        assertEq(vault.erc20TokenBalances(address(erc20Token)), 10e18);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 3e18;
        amounts[1] = 3e18;

        vm.prank(deployer);
        vault.transferERC20(address(erc20Token), accounts, amounts);

        assertEq(erc20Token.balanceOf(address(vault)), 4e18);
        assertEq(vault.erc20TokenBalances(address(erc20Token)), 4e18);
    }

    function test_TransferERC20AmountTooBig() public {
        assertEq(erc20Token.balanceOf(address(vault)), 10e18);
        assertEq(vault.erc20TokenBalances(address(erc20Token)), 10e18);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 10e18;
        amounts[1] = 10e18;

        vm.prank(deployer);
        vm.expectRevert(CommunityVault.CommunityVault_ERC20TransferAmountTooBig.selector);
        vault.transferERC20(address(erc20Token), accounts, amounts);
    }
}

contract DepositERC20Test is CommunityVaultBaseERC20Test {
    function testSuccessfulDepositERC20() public {
        uint256 depositAmount = 5;
        uint256 initialVaultBalance = erc20Token.balanceOf(address(vault));
        uint256 initialTokenBalanceValue = vault.erc20TokenBalances(address(erc20Token));

        vm.startPrank(accounts[0]);
        erc20Token.approve(address(vault), depositAmount);
        vault.depositERC20(address(erc20Token), depositAmount);
        vm.stopPrank();

        assertEq(erc20Token.balanceOf(address(vault)), initialVaultBalance + depositAmount);
        assertEq(vault.erc20TokenBalances(address(erc20Token)), initialTokenBalanceValue + depositAmount);
    }

    function testDepositZeroTokens() public {
        vm.prank(accounts[0]);
        vm.expectRevert(CommunityVault.CommunityVault_DepositAmountZero.selector);
        vault.depositERC20(address(erc20Token), 0);
    }
}

contract CommunityVaultWithdrawUntrackedERC20Test is CommunityVaultBaseERC20Test {
    function setUp() public virtual override {
        CommunityVaultBaseERC20Test.setUp();
        assertEq(erc20Token.balanceOf(accounts[0]), 10e18);

        vm.startPrank(accounts[0]);

        // deposit 2 tokens
        erc20Token.approve(address(vault), 2e18);
        vault.depositERC20(address(erc20Token), 2e18);

        // trasfer 8 tokens
        erc20Token.transfer(address(vault), 8e18);
        vm.stopPrank();
    }

    function testRevertWithdrawalIfAmountIsMoreThanTheUntracked() public {
        vm.prank(deployer);
        vm.expectRevert(CommunityVault.CommunityVault_AmountExceedsUntrackedBalanceERC20.selector);
        vault.withdrawUntrackedERC20(address(erc20Token), 9e18, accounts[0]);
    }

    function testSuccessfulWithdrawal() public {
        assertEq(erc20Token.balanceOf(accounts[0]), 0e18);
        assertEq(erc20Token.balanceOf(address(vault)), 10e18);

        vm.prank(deployer);
        vault.withdrawUntrackedERC20(address(erc20Token), 8e18, accounts[0]);

        assertEq(erc20Token.balanceOf(accounts[0]), 8e18);
        assertEq(erc20Token.balanceOf(address(vault)), 2e18);
    }
}

contract CommunityVaultBaseERC721Test is CommunityVaultTest {
    function setUp() public virtual override {
        CommunityVaultTest.setUp();

        // mint 4 token to user
        address user = accounts[0];
        erc721Token.mint(user);
        erc721Token.mint(user);
        erc721Token.mint(user);
        erc721Token.mint(user);
    }
}

contract CommunityVaultBaseTransferERC721Test is CommunityVaultBaseERC721Test {
    function setUp() public virtual override {
        CommunityVaultBaseERC721Test.setUp();

        address user = accounts[0];

        // user transfer 2 tokens to the vault
        uint256[] memory ids = new uint256[](3);
        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 2;

        vm.startPrank(user);
        erc721Token.approve(address(vault), ids[0]);
        erc721Token.approve(address(vault), ids[1]);
        erc721Token.approve(address(vault), ids[2]);
        vault.depositERC721(address(erc721Token), ids);
        vm.stopPrank();
    }
}

contract TransferERC721ByNonAdminTest is CommunityVaultBaseTransferERC721Test {
    function setUp() public virtual override {
        CommunityVaultBaseTransferERC721Test.setUp();
    }

    function test_RevertIfCalledByNonAdmin() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 0;
        ids[1] = 1;

        vm.prank(accounts[0]);
        vm.expectRevert(CommunityOwnable.CommunityOwnable_NotAuthorized.selector);

        vault.transferERC721(address(erc721Token), accounts, ids);
    }
}

contract TransferERC721ByAdminTest is CommunityVaultBaseTransferERC721Test {
    function setUp() public virtual override {
        CommunityVaultBaseTransferERC721Test.setUp();
    }

    function test_LengthMismatch() public {
        uint256[] memory ids = new uint256[](1);
        ids[0] = 0;

        vm.prank(deployer);
        vm.expectRevert(CommunityVault.CommunityVault_LengthMismatch.selector);
        vault.transferERC721(address(erc721Token), accounts, ids);
    }

    function test_NoRecipients() public {
        uint256[] memory ids = new uint256[](0);
        address[] memory tmpAccounts = new address[](0);

        vm.prank(deployer);
        vm.expectRevert(CommunityVault.CommunityVault_NoRecipients.selector);
        vault.transferERC721(address(erc721Token), tmpAccounts, ids);
    }

    function test_AdminCanTransferERC721() public {
        assertEq(erc721Token.balanceOf(address(vault)), 3);
        assertEq(vault.erc721TokenBalances(address(erc721Token)), 3);

        // accounts[0] has 1 token with id 3
        assertEq(erc721Token.balanceOf(accounts[0]), 1);
        assertEq(erc721Token.balanceOf(accounts[1]), 0);

        assertEq(erc721Token.ownerOf(0), address(vault));
        assertEq(erc721Token.ownerOf(1), address(vault));
        assertEq(erc721Token.ownerOf(2), address(vault));

        uint256[] memory ids = new uint256[](2);
        ids[0] = 0;
        ids[1] = 1;

        vm.prank(deployer);
        vault.transferERC721(address(erc721Token), accounts, ids);

        assertEq(erc721Token.balanceOf(address(vault)), 1);
        assertEq(vault.erc721TokenBalances(address(erc721Token)), 1);

        assertEq(erc721Token.balanceOf(accounts[0]), 2);
        assertEq(erc721Token.balanceOf(accounts[1]), 1);
    }

    function test_RevertOnTransferERC721IfNotDeposited() public {
        // id 3 is not deposited
        assertEq(erc721Token.ownerOf(3), address(accounts[0]));

        uint256[] memory ids = new uint256[](1);
        ids[0] = 3;

        address[] memory accountsList = new address[](1);
        accountsList[0] = accounts[0];

        vm.prank(deployer);
        vm.expectRevert(CommunityVault.CommunityVault_ERC721TokenNotDeposited.selector);
        vault.transferERC721(address(erc721Token), accountsList, ids);
    }
}

contract CommunityVaultDepositERC721Test is CommunityVaultBaseERC721Test {
    function setUp() public virtual override {
        CommunityVaultBaseERC721Test.setUp();
    }

    function testSuccessfulDepositERC721() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 0;
        ids[1] = 1;

        uint256 initialVaultBalance = erc721Token.balanceOf(address(vault));
        uint256 initialTokenBalanceValue = vault.erc721TokenBalances(address(erc721Token));

        vm.startPrank(accounts[0]);
        erc721Token.approve(address(vault), ids[0]);
        erc721Token.approve(address(vault), ids[1]);
        vault.depositERC721(address(erc721Token), ids);
        vm.stopPrank();

        assertEq(erc721Token.balanceOf(address(vault)), initialVaultBalance + 2);
        assertEq(vault.erc721TokenBalances(address(erc721Token)), initialTokenBalanceValue + 2);
    }
}

contract CommunityVaultWithdrawUntrackedERC721Test is CommunityVaultBaseERC721Test {
    function setUp() public virtual override {
        CommunityVaultBaseERC721Test.setUp();
        vm.startPrank(accounts[0]);
        // trasfer to contract ids 0 and 1
        erc721Token.transferFrom(accounts[0], address(vault), 0);
        erc721Token.transferFrom(accounts[0], address(vault), 1);

        // deposit id 2
        uint256[] memory ids = new uint256[](1);
        ids[0] = 2;
        erc721Token.approve(address(vault), 2);
        vault.depositERC721(address(erc721Token), ids);
        vm.stopPrank();
    }

    function testRevertWithdrawalIfTokenIsTracked() public {
        uint256[] memory ids = new uint256[](1);
        ids[0] = 2;

        assertEq(erc721Token.ownerOf(2), address(vault));
        assertEq(vault.getERC721DepositedTokenByIndex(address(erc721Token), 0), 2);

        vm.prank(deployer);
        vm.expectRevert(CommunityVault.CommunityVault_CannotWithdrawTrackedERC721.selector);
        vault.withdrawUntrackedERC721(address(erc721Token), ids, accounts[0]);
    }

    function testSuccessfulWithdrUntrackedERC721() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 0;
        ids[1] = 1;

        assertEq(erc721Token.ownerOf(0), address(vault));
        assertEq(erc721Token.ownerOf(1), address(vault));

        vm.prank(deployer);
        vault.withdrawUntrackedERC721(address(erc721Token), ids, accounts[0]);

        assertEq(erc721Token.ownerOf(0), accounts[0]);
        assertEq(erc721Token.ownerOf(1), accounts[0]);
    }
}

contract CommunityVaultMigrationTest is CommunityVaultTest {
    CommunityVault internal newVault;
    TestERC20Token internal erc20Token2;
    TestERC20Token internal erc20Token3;

    function setUp() public virtual override {
        CommunityVaultTest.setUp();

        newVault = new CommunityVault(address(ownerToken), address(masterToken));
        erc20Token2 = new TestERC20Token();
        erc20Token3 = new TestERC20Token();

        vm.startPrank(deployer);
        // mint erc20 tokens and deposit
        erc20Token.mint(deployer, 10e18);
        erc20Token.approve(address(vault), 10e18);
        vault.depositERC20(address(erc20Token), 10e18);
        erc20Token2.mint(deployer, 5e18);
        erc20Token2.approve(address(vault), 5e18);
        vault.depositERC20(address(erc20Token2), 5e18);

        // mint erc721 tokens and deposit
        erc721Token.mint(deployer);
        erc721Token.mint(deployer);
        erc721Token.mint(deployer);
        erc721Token.mint(deployer);
        // id 4 is not deposited
        erc721Token.mint(deployer);

        uint256[] memory ids = new uint256[](4);
        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 2;
        ids[3] = 3;
        erc721Token.approve(address(vault), 0);
        erc721Token.approve(address(vault), 1);
        erc721Token.approve(address(vault), 2);
        erc721Token.approve(address(vault), 3);
        vault.depositERC721(address(erc721Token), ids);

        vm.stopPrank();
    }

    function test_migrateERC20RevertsIfNotAuthorized() public {
        vm.prank(accounts[0]);
        vm.expectRevert(CommunityOwnable.CommunityOwnable_NotAuthorized.selector);

        address[] memory tokens = new address[](0);
        vault.migrateERC20Tokens(tokens);
    }

    function test_migrateERC721RevertsIfNotAuthorized() public {
        vm.prank(accounts[0]);
        vm.expectRevert(CommunityOwnable.CommunityOwnable_NotAuthorized.selector);

        uint256[] memory ids = new uint256[](0);
        vault.migrateERC721Tokens(address(0), ids);
    }

    function test_migrateERC20RevertsIfNewImplementationIsNotSet() public {
        assertEq(vault.newImplementation(), address(0));
        vm.prank(deployer);
        vm.expectRevert(CommunityVault.CommunityVault_NewImplementationNotSet.selector);

        address[] memory tokens = new address[](0);
        vault.migrateERC20Tokens(tokens);
    }

    function test_migrateERC721RevertsIfNewImplementationIsNotSet() public {
        assertEq(vault.newImplementation(), address(0));
        vm.prank(deployer);
        vm.expectRevert(CommunityVault.CommunityVault_NewImplementationNotSet.selector);

        uint256[] memory ids = new uint256[](0);
        vault.migrateERC721Tokens(address(0), ids);
    }

    function test_migrateERC20RevertsIfTokenBalanceIsZero() public {
        vm.startPrank(deployer);
        vault.setNewImplementation(address(newVault));

        assertEq(erc20Token3.balanceOf(address(vault)), 0);
        vm.expectRevert(CommunityVault.CommunityVault_ZeroBalance.selector);

        address[] memory tokens = new address[](1);
        tokens[0] = address(erc20Token3);

        vault.migrateERC20Tokens(tokens);

        vm.stopPrank();
    }

    function test_migrateERC20Tokens() public {
        vm.startPrank(deployer);

        vault.setNewImplementation(address(newVault));
        assertEq(erc20Token.balanceOf(address(vault)), 10e18);
        assertEq(erc20Token2.balanceOf(address(vault)), 5e18);
        assertEq(erc20Token.balanceOf(address(newVault)), 0);
        assertEq(erc20Token2.balanceOf(address(newVault)), 0);

        address[] memory tokens = new address[](2);
        tokens[0] = address(erc20Token);
        tokens[1] = address(erc20Token2);
        vault.migrateERC20Tokens(tokens);

        assertEq(erc20Token.balanceOf(address(vault)), 0);
        assertEq(erc20Token2.balanceOf(address(vault)), 0);
        assertEq(erc20Token.balanceOf(address(newVault)), 10e18);
        assertEq(erc20Token2.balanceOf(address(newVault)), 5e18);

        vm.stopPrank();
    }

    function test_migrateERC721TokensRevertsIfTokenNotDeposited() public {
        vm.startPrank(deployer);

        vault.setNewImplementation(address(newVault));
        assertEq(erc721Token.ownerOf(4), deployer);

        uint256[] memory ids = new uint256[](1);
        ids[0] = 4;

        vm.expectRevert(CommunityVault.CommunityVault_ERC721TokenNotDeposited.selector);
        vault.migrateERC721Tokens(address(erc721Token), ids);

        vm.stopPrank();
    }

    function test_migrateERC721Tokens() public {
        vm.startPrank(deployer);

        vault.setNewImplementation(address(newVault));
        assertEq(erc721Token.ownerOf(0), address(vault));
        assertEq(erc721Token.ownerOf(1), address(vault));
        assertEq(erc721Token.ownerOf(2), address(vault));
        assertEq(erc721Token.ownerOf(3), address(vault));

        uint256[] memory ids = new uint256[](4);
        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 2;
        ids[3] = 3;

        vault.migrateERC721Tokens(address(erc721Token), ids);

        assertEq(erc721Token.ownerOf(0), address(newVault));
        assertEq(erc721Token.ownerOf(1), address(newVault));
        assertEq(erc721Token.ownerOf(2), address(newVault));
        assertEq(erc721Token.ownerOf(3), address(newVault));

        vm.stopPrank();
    }
}
