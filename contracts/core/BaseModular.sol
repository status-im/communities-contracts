// SPDX-License-Identifier: Mozilla Public License 2.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract BaseModular is AccessControlEnumerable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    function addModule(bytes32 role, address account) public {
        require(hasRole(ADMIN_ROLE, _msgSender()), "ModularERC721: must have admin role");
        require(Address.isContract(account), "ModularERC721: module must be a contract");
        _grantRole(role, account);
    }

    function removeModule(bytes32 role, address account) public onlyRole(ADMIN_ROLE) {
        require(hasRole(ADMIN_ROLE, _msgSender()), "ModularERC721: must have admin role");
        _grantRole(role, account);
    }
}
