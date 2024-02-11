// SPDX-License-Identifier: Mozilla Public License 2.0
pragma solidity ^0.8.17;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { CommunityOwnable } from "../CommunityOwnable.sol";

abstract contract BaseToken is Context, ERC721Enumerable, CommunityOwnable {
    using Counters for Counters.Counter;

    error BaseToken_MaxSupplyLowerThanTotalSupply();
    error BaseToken_MaxSupplyReached();
    error BaseToken_NotRemoteBurnable();
    error BaseToken_NotTransferable();

    /// @notice Emits a custom mint event for Status applications to listen to
    /// @dev This is doubling the {Transfer} event from ERC721 but we need to emit this
    /// so Status applications have a way to easily distinguish between transactions that have
    /// a similar event footprint but are semantically different.
    /// @param from The address that minted the token
    /// @param to The address that received the token
    /// @param tokenId The token ID that was minted
    event StatusMint(address indexed from, address indexed to, uint256 indexed tokenId);

    // State variables

    Counters.Counter private _tokenIdTracker;

    /**
     * If we want unlimited total supply we should set maxSupply to 2^256-1.
     */
    uint256 public maxSupply;
    /**
     * If set to true, the contract owner can burn any token.
     */
    bool public immutable remoteBurnable;

    /**
     * If set to false it acts as a soulbound token.
     */
    bool public immutable transferable;

    string public baseTokenURI;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        bool _remoteBurnable,
        bool _transferable,
        string memory _baseTokenURI,
        address _ownerToken,
        address _masterToken
    )
        ERC721(_name, _symbol)
        CommunityOwnable(_ownerToken, _masterToken)
    {
        maxSupply = _maxSupply;
        remoteBurnable = _remoteBurnable;
        transferable = _transferable;
        baseTokenURI = _baseTokenURI;
    }

    // Events

    // External functions

    function setMaxSupply(uint256 newMaxSupply) external virtual onlyCommunityOwnerOrTokenMaster {
        if (newMaxSupply < mintedCount()) {
            revert BaseToken_MaxSupplyLowerThanTotalSupply();
        }
        maxSupply = newMaxSupply;
    }

    /**
     * @dev Creates a new token for each address in `addresses`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     */
    function mintTo(address[] memory addresses) public onlyCommunityOwnerOrTokenMaster {
        if (_tokenIdTracker.current() + addresses.length > maxSupply) {
            revert BaseToken_MaxSupplyReached();
        }
        _mintTo(addresses);
    }

    // Public functions

    function mintedCount() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    /**
     * @notice remoteBurn allows the owner to burn a token
     * @param tokenIds The list of token IDs to be burned
     */
    function remoteBurn(uint256[] memory tokenIds) public onlyCommunityOwnerOrTokenMaster {
        if (!remoteBurnable) revert BaseToken_NotRemoteBurnable();

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _burn(tokenIds[i]);
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Internal functions

    /**
     * @notice
     * @dev
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _mintTo(address[] memory addresses) internal {
        // We cannot just use totalSupply() to create the new tokenId because tokens
        // can be burned so we use a separate counter.
        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], _tokenIdTracker.current(), "");
            emit StatusMint(address(0), addresses[i], _tokenIdTracker.current());
            _tokenIdTracker.increment();
        }
    }

    /**
     * @notice
     * @dev
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    )
        internal
        virtual
        override(ERC721Enumerable)
    {
        if (from != address(0) && to != address(0) && !transferable) {
            revert BaseToken_NotTransferable();
        }
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    // Private functions
}
