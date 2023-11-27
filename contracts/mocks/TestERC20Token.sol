// SPDX-License-Identifier: Mozilla Public License 2.0
pragma solidity ^0.8.17;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC20Token is ERC20 {
    constructor() ERC20("Test Token", "TEST") { }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
