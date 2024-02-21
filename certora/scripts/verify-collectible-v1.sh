certoraRun \
  contracts/tokens/CollectibleV1.sol \
  certora/harness/CollectibleV1Harness.sol \
  contracts/tokens/OwnerToken.sol \
  contracts/tokens/MasterToken.sol \
--verify CollectibleV1Harness:certora/specs/CollectibleV1.spec \
--link CollectibleV1Harness:ownerToken=OwnerToken \
--link CollectibleV1Harness:masterToken=MasterToken \
--packages @openzeppelin=lib/openzeppelin-contracts \
--optimistic_loop \
--loop_iter 3 \
--rule_sanity "basic" \
--wait_for_results "all" \
--msg "Verifying CollectibleV1.sol"

