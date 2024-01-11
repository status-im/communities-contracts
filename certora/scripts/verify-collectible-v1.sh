certoraRun \
  contracts/tokens/CollectibleV1.sol \
--verify CollectibleV1:certora/specs/CollectibleV1.spec \
--packages @openzeppelin=lib/openzeppelin-contracts \
--optimistic_loop \
--rule_sanity "basic" \
--wait_for_results "all" \
--msg "Verifying CollectibleV1.sol"

