// SPDX-License-Identifier: Mozilla Public License 2.0
pragma solidity ^0.8.17;

import {CollectibleV1} from "../../contracts/tokens/CollectibleV1.sol";

contract CollectibleV1Harness is CollectibleV1 {
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
        CollectibleV1(
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
