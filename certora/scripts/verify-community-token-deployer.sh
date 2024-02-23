certoraRun \
  contracts/CommunityTokenDeployer.sol \
  contracts/CommunityOwnerTokenRegistry.sol \
  contracts/factories/CommunityOwnerTokenFactory.sol \
  contracts/factories/CommunityMasterTokenFactory.sol \
--verify CommunityTokenDeployer:certora/specs/CommunityTokenDeployer.spec \
--link CommunityTokenDeployer:deploymentRegistry=CommunityOwnerTokenRegistry \
--link CommunityTokenDeployer:ownerTokenFactory=CommunityOwnerTokenFactory \
--link CommunityTokenDeployer:masterTokenFactory=CommunityMasterTokenFactory \
--packages @openzeppelin=lib/openzeppelin-contracts \
--optimistic_loop \
--rule_sanity "basic" \
--msg "Verifying CommunityTokenDeployer.sol"

