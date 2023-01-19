// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./core/ModularERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract BuyableERC721 is ModularERC721 {
    using SafeERC20 for IERC20;

    address public beneficiary;
    address public paymentToken;
    uint256 public tokenPrice;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        address _beneficiary,
        address _paymentToken,
        uint256 _tokenPrice
    ) ModularERC721(name, symbol, baseTokenURI) {
        beneficiary = _beneficiary;
        paymentToken = _paymentToken;
        tokenPrice = _tokenPrice;
    }

    function setBeneficiary(address _account) public {
        require(hasRole(ADMIN_ROLE, _msgSender()), "ModularERC721: must have admin role");
        require(_account != address(0x0), "BuyableERC721: beneficiary cannot be 0x00");
        beneficiary = _account;
    }

    function setPaymentToken(address _token) public {
        require(hasRole(ADMIN_ROLE, _msgSender()), "ModularERC721: must have admin role");
        require(_token != address(0x0), "BuyableERC721: token cannot be 0x00");
        paymentToken = _token;
    }

    function setTokenPrice(uint256 _price) public {
        require(hasRole(ADMIN_ROLE, _msgSender()), "ModularERC721: must have admin role");
        tokenPrice = _price;
    }

    function mint() public {
        IERC20(paymentToken).safeTransferFrom(msg.sender, beneficiary, tokenPrice);
        _mintTo(msg.sender);
    }
}
