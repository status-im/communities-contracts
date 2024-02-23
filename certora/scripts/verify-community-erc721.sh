certoraRun \
  contracts/tokens/CommunityERC721.sol \
  certora/harness/CommunityERC721Harness.sol \
--verify CommunityERC721Harness:certora/specs/CommunityERC721.spec \
--packages @openzeppelin=lib/openzeppelin-contracts \
--optimistic_loop \
--loop_iter 3 \
--rule_sanity "basic" \
--msg "Verifying CommunityERC721.sol"

