// SPDX-License-Identifier: Mozilla Public License 2.0

pragma solidity ^0.8.17;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { CommunityOwnable } from "./CommunityOwnable.sol";

/**
 * @title CommunityVault
 * @dev This contract acts as a Vault for storing ERC20 and ERC721 tokens.
 *      It allows any user to deposit tokens into the vault.
 *      Only community owners, as defined in the CommunityOwnable contract, have
 *      permissions to transfer these tokens out of the vault.
 */
contract CommunityVault is CommunityOwnable {
    using SafeERC20 for IERC20;

    error CommunityVault_LengthMismatch();
    error CommunityVault_NoRecipients();
    error CommunityVault_TransferAmountZero();

    constructor(address _ownerToken, address _masterToken) CommunityOwnable(_ownerToken, _masterToken) { }

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
            IERC721(token).safeTransferFrom(address(this), recipients[i], tokenIds[i]);
        }
    }
}
