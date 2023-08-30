if [[ "$1" ]]
then
  RULE="--rule $1"
fi

if [[ "$2" ]]
then
  MSG="- $2"
fi

certoraRun \
  ./contracts/tokens/CollectibleV1.sol \
  --verify CollectibleV1:./specs/CollectibleV1.spec \
  --packages @openzeppelin=lib/openzeppelin-contracts \
  --optimistic_loop \
  --loop_iter 3 \
  --rule_sanity \
  --send_only \
  $RULE \
  --msg "CollectibleV1: $RULE $MSG"

