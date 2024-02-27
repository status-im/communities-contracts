# Changelog

All notable changes to this project will be documented in this file. See [commit-and-tag-version](https://github.com/absolute-version/commit-and-tag-version) for commit guidelines.

## 1.0.0 (2024-02-28)

### ⚠ BREAKING CHANGES

- **OwnerToken:** `OwnerToken.setMaxSupply(uint256)` now emits
  `OwnerToken.OwnerToken_MaxSupplyLocked.selector` instead of `"max supply

* Any references to `CollectibleV1` must be replaced with
  `CommunityERC721`

- **OwnerToken:** use custom error in `setMaxSupply` ([fcf30cd](https://github.com/status-im/communities-contracts/commit/fcf30cde8faf03143b680172b03da7cf47691958))

* rename `CollectibleV1`to `CommunityERC721` ([a84c46b](https://github.com/status-im/communities-contracts/commit/a84c46b3d6c283d0699ca568a67d7f6d84cdc994)), closes [#46](https://github.com/status-im/communities-contracts/issues/46) [#46](https://github.com/status-im/communities-contracts/issues/46)

### Features

- Add base url to community ERC20 ([#21](https://github.com/status-im/communities-contracts/issues/21)) ([1085ee8](https://github.com/status-im/communities-contracts/commit/1085ee83089f44ce9c5492835f90359279302500))
- add certora CI integration ([#24](https://github.com/status-im/communities-contracts/issues/24)) ([8773220](https://github.com/status-im/communities-contracts/commit/8773220abe99e0cd318c722b1178537ec3824c4b))
- add token specific deploy events in deployer contract ([#14](https://github.com/status-im/communities-contracts/issues/14)) ([16121a4](https://github.com/status-im/communities-contracts/commit/16121a4f7203a3dd1c1803748c1372b1a6fde0e7))
- **CollectibleV1:** add `safeBatchTransferFrom` capabilities ([a8e509b](https://github.com/status-im/communities-contracts/commit/a8e509baf7fba0ead467ad438b220f0b412f1886)), closes [#41](https://github.com/status-im/communities-contracts/issues/41) [#41](https://github.com/status-im/communities-contracts/issues/41) [#42](https://github.com/status-im/communities-contracts/issues/42) [#43](https://github.com/status-im/communities-contracts/issues/43) [#44](https://github.com/status-im/communities-contracts/issues/44)
- implement `CommunityTokenDeployer` contract ([#2](https://github.com/status-im/communities-contracts/issues/2)) ([4be8613](https://github.com/status-im/communities-contracts/commit/4be8613d6ee732d15c02d9e2c6a4544b924e69aa))
- introduce custom `StatusMint()` events ([#18](https://github.com/status-im/communities-contracts/issues/18)) ([ea7ef0e](https://github.com/status-im/communities-contracts/commit/ea7ef0ef61c8173a3744aab660eb2a899c2a6ff5))
