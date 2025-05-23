//// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import { Script } from "forge-std/Script.sol";

contract DeploymentConfig is Script {
    error DeploymentConfig_InvalidDeployerAddress();

    struct TokenConfig {
        string name;
        string symbol;
        string baseURI;
        bytes signerPublicKey;
    }

    TokenConfig public ownerTokenConfig;
    TokenConfig public masterTokenConfig;

    address public immutable deployer;

    constructor(address _broadcaster) {
        if (_broadcaster == address(0)) {
            revert DeploymentConfig_InvalidDeployerAddress();
        }
        deployer = _broadcaster;
        if (block.chainid == 31_337) {
            (ownerTokenConfig, masterTokenConfig) = getOrCreateAnvilEthConfig();
        }
    }

    function getOrCreateAnvilEthConfig() public pure returns (TokenConfig memory, TokenConfig memory) {
        TokenConfig memory _ownerTokenConfig = TokenConfig({
            name: "Owner",
            symbol: "OWNR",
            baseURI: "http://local.owner",
            signerPublicKey: bytes("some public key")
        });
        TokenConfig memory _masterTokenConfig =
            TokenConfig({ name: "Master", symbol: "MSTR", baseURI: "http://local.master", signerPublicKey: "" });
        return (_ownerTokenConfig, _masterTokenConfig);
    }

    function getOwnerTokenConfig() public view returns (TokenConfig memory) {
        return ownerTokenConfig;
    }

    function getMasterTokenConfig() public view returns (TokenConfig memory) {
        return masterTokenConfig;
    }

    // This function is a hack to have it excluded by `forge coverage` until
    // https://github.com/foundry-rs/foundry/issues/2988 is fixed.
    // See: https://github.com/foundry-rs/foundry/issues/2988#issuecomment-1437784542
    // for more info.
    // solhint-disable-next-line
    function test() public { }
}
