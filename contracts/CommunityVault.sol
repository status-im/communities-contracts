// SPDX-License-Identifier: Mozilla Public License 2.0

pragma solidity ^0.8.17;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { CommunityOwnable } from "./CommunityOwnable.sol";

/**
 * @title CommunityVault
 * @dev This contract acts as a Vault for storing ERC20 and ERC721 tokens.
 *      It allows any user to deposit tokens into the vault.
 *      Only community owners, as defined in the CommunityOwnable contract, have
 *      permissions to transfer these tokens out of the vault.
 */
contract CommunityVault is CommunityOwnable, IERC721Receiver {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    event ERC20Deposited(address indexed depositor, address indexed token, uint256 amount);
    event ERC721Deposited(address indexed depositor, address indexed token, uint256 tokenId);

    error CommunityVault_LengthMismatch();
    error CommunityVault_NoRecipients();
    error CommunityVault_TransferAmountZero();
    error CommunityVault_ERC20TransferAmountTooBig();
    error CommunityVault_DepositAmountZero();
    error CommunityVault_IndexOutOfBounds();
    error CommunityVault_ERC721TokenAlreadyDeposited();
    error CommunityVault_ERC721TokenNotDeposited();

    mapping(address => uint256) public erc20TokenBalances;
    mapping(address => EnumerableSet.UintSet) private erc721TokenIds;

    constructor(address _ownerToken, address _masterToken) CommunityOwnable(_ownerToken, _masterToken) { }

    /**
     * @dev Allows anyone to deposit ERC20 tokens into the vault.
     * @param token The address of the ERC20 token to deposit.
     * @param amount The amount of tokens to deposit.
     */
    function depositERC20(address token, uint256 amount) external {
        if (amount == 0) {
            revert CommunityVault_DepositAmountZero();
        }

        // Transfer tokens from the sender to this contract
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // Update the total balance of the token in the vault
        erc20TokenBalances[token] += amount;

        // Emit an event for the deposit (optional, but recommended for tracking)
        emit ERC20Deposited(msg.sender, token, amount);
    }

    /**
     * @dev Allows anyone to deposit multiple ERC721 tokens into the vault.
     * @param token The address of the ERC721 token to deposit.
     * @param tokenIds The IDs of the tokens to deposit.
     */
    function depositERC721(address token, uint256[] memory tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            // Add the token ID to the EnumerableSet for the given token
            bool added = erc721TokenIds[token].add(tokenIds[i]);
            if (!added) {
                revert CommunityVault_ERC721TokenAlreadyDeposited();
            }

            // Transfer the token from the sender to this contract
            IERC721(token).safeTransferFrom(msg.sender, address(this), tokenIds[i]);

            // Emit an event for the deposit
            emit ERC721Deposited(msg.sender, token, tokenIds[i]);
        }
    }

    /**
     * @dev Gets the count of ERC721 tokens deposited for a given token address.
     * @param token The address of the ERC721 token.
     * @return The count of tokens deposited.
     */
    function erc721TokenBalances(address token) public view returns (uint256) {
        return erc721TokenIds[token].length();
    }

    /**
     * @dev Retrieves a deposited ERC721 token ID by index.
     * @param token The address of the ERC721 token.
     * @param index The index of the token ID to retrieve.
     * @return The token ID at the given index.
     */
    function getERC721DepositedTokenByIndex(address token, uint256 index) public view returns (uint256) {
        if (index >= erc721TokenIds[token].length()) {
            revert CommunityVault_IndexOutOfBounds();
        }

        return erc721TokenIds[token].at(index);
    }

    /**
     * @dev Transfers ERC20 tokens to a list of addresses.
     * @param token The ERC20 token address.
     * @param recipients The list of recipient addresses.
     * @param amounts The list of amounts to transfer to each recipient.
     */
    function transferERC20(
        address token,
        address[] calldata recipients,
        uint256[] calldata amounts
    )
        external
        onlyCommunityOwnerOrTokenMaster
    {
        if (recipients.length != amounts.length) {
            revert CommunityVault_LengthMismatch();
        }

        if (recipients.length == 0) {
            revert CommunityVault_NoRecipients();
        }

        for (uint256 i = 0; i < recipients.length; i++) {
            if (amounts[i] == 0) {
                revert CommunityVault_TransferAmountZero();
            }

            if (amounts[i] > erc20TokenBalances[token]) {
                revert CommunityVault_ERC20TransferAmountTooBig();
            }

            erc20TokenBalances[token] -= amounts[i];
            IERC20(token).safeTransfer(recipients[i], amounts[i]);
        }
    }

    /**
     * @dev Transfers ERC721 tokens to a list of addresses.
     * @param token The ERC721 token address.
     * @param recipients The list of recipient addresses.
     * @param tokenIds The list of token IDs to transfer to each recipient.
     */
    function transferERC721(
        address token,
        address[] calldata recipients,
        uint256[] calldata tokenIds
    )
        external
        onlyCommunityOwnerOrTokenMaster
    {
        if (recipients.length != tokenIds.length) {
            revert CommunityVault_LengthMismatch();
        }

        if (recipients.length == 0) {
            revert CommunityVault_NoRecipients();
        }

        for (uint256 i = 0; i < recipients.length; i++) {
            bool removed = erc721TokenIds[token].remove(tokenIds[i]);
            if (!removed) {
                revert CommunityVault_ERC721TokenNotDeposited();
            }

            IERC721(token).safeTransferFrom(address(this), recipients[i], tokenIds[i]);
        }
    }

    /**
     * @dev Handles the receipt of an ERC721 token.
     * @return bytes4 Returns `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     *          to indicate the contract implements `onERC721Received` as per ERC721.
     */
    function onERC721Received(address, address, uint256, bytes calldata) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
