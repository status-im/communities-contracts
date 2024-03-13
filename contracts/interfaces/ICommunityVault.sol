// SPDX-License-Identifier: Mozilla Public License 2.0

pragma solidity ^0.8.17;

interface ICommunityVault {
    function depositERC20(address token, uint256 amount) external;
    function depositERC721(address token, uint256[] calldata tokenIds) external;
}
