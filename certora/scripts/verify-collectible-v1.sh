certoraRun \
  contracts/tokens/CollectibleV1.sol \
  certora/harness/CollectibleV1Harness.sol \
--verify CollectibleV1Harness:certora/specs/CollectibleV1.spec \
--packages @openzeppelin=lib/openzeppelin-contracts \
--optimistic_loop \
--loop_iter 3 \
--rule_sanity "basic" \
--wait_for_results "all" \
--msg "Verifying CollectibleV1.sol"

