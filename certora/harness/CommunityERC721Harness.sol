// SPDX-License-Identifier: Mozilla Public License 2.0
pragma solidity ^0.8.17;

import {CommunityERC721} from "../../contracts/tokens/CommunityERC721.sol";

contract CommunityERC721Harness is CommunityERC721 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        bool remoteBurnable,
        bool transferable,
        string memory baseURI,
        address ownerToken,
        address masterToken
    )
        CommunityERC721(
            name,
            symbol,
            maxSupply,
            remoteBurnable,
            transferable,
            baseURI,
            ownerToken,
            masterToken
        )
    {}

    /**
     * @notice A helper function to count the number of occurrences of an address in a list.
     */
    function countAddressOccurrences(
        address[] memory list,
        address addr
    ) external pure returns (uint) {
        uint256 count = 0;
        for (uint256 i = 0; i < list.length; i++) {
            if (list[i] == addr) {
                count++;
            }
        }
        return count;
    }
}
