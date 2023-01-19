// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./BuyableERC721.sol";

contract BuyableSoulbound is BuyableERC721 {
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        address _beneficiary,
        address _paymentToken,
        uint256 _tokenPrice
    ) BuyableERC721 (name, symbol, baseTokenURI, _beneficiary, _paymentToken, _tokenPrice) {
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override {
        require(from == address(0) || to == address(0), "BuyableERC721: cannot be transferred");
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }
}
