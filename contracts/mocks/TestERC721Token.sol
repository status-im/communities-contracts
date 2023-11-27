// SPDX-License-Identifier: Mozilla Public License 2.0
pragma solidity ^0.8.17;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TestERC721Token is ERC721 {
    uint256 private currentTokenId;

    constructor() ERC721("Test NFT", "TNFT") { }

    function mint(address to) external {
        _mint(to, currentTokenId);
        currentTokenId++;
    }
}
