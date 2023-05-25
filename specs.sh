if [[ "$1" ]]
then
  RULE="--rule $1"
fi

if [[ "$2" ]]
then
  MSG="- $2"
fi

certoraRun \
  ./contracts/mvp/CollectibleV1.sol \
  --verify CollectibleV1:./specs/mvp/CollectibleV1.spec \
  --packages @openzeppelin=node_modules/@openzeppelin \
  --optimistic_loop \
  --loop_iter 3 \
  --rule_sanity \
  --send_only \
  $RULE \
  --msg "CollectibleV1: $RULE $MSG"

