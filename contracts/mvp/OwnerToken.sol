// SPDX-License-Identifier: Mozilla Public License 2.0
pragma solidity ^0.8.17;

import "./BaseToken.sol";
import "./MasterToken.sol";

contract OwnerToken is BaseToken {
    event MasterTokenCreated(address masterToken);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        string memory _masterName,
        string memory _masterSymbol,
        string memory _masterBaseTokenURI
    ) BaseToken(
        _name,
        _symbol,
        1,
        false,
        true,
        _baseTokenURI,
        address(this),
        address(this))
    {
        MasterToken masterToken = new MasterToken(_masterName, _masterSymbol, _masterBaseTokenURI, address(this));
        emit MasterTokenCreated(address(masterToken));
    }

    function setMaxSupply(uint256 _newMaxSupply) override external onlyOwner {
        revert("max supply locked");
    }
}
