methods {
  balanceOf(address) returns (uint) envfree;
  ownerOf(uint256 tokenId) returns (address) envfree;
  transferable() returns (bool) envfree;
  totalSupply() returns (uint) envfree;
  owner() returns (address) envfree;
  maxSupply() returns (uint) envfree;
}

/* rule sanity(env e, method f) { */
/*     calldataarg args; */
/*     f(e, args); */
/*     assert false; */
/* } */

rule mintTo_FromOwner {
  address owner;
  address recipient_1;
  address recipient_2;

  env e;
  require recipient_1 != recipient_2;
  require e.msg.sender == owner;
  require owner() == owner;
  require maxSupply() == 100000;
  require totalSupply() == 0;
  require balanceOf(recipient_1) == 0;
  require balanceOf(recipient_2) == 0;

  assert balanceOf(recipient_1) == 0, "balance of recipient_1 should be 0";
  assert balanceOf(recipient_2) == 0, "balance of recipient_2 should be 0";

  mintTo(e, [recipient_1, recipient_2]);

  assert balanceOf(recipient_1) == 1, "balance of recipient_1 should be 1";
  assert balanceOf(recipient_2) == 1, "balance of recipient_2 should be 1";
}

rule transferNFT_validOwner {
  address sender;
  address recipient;
  uint token_id;

  env e;
  require e.msg.sender == sender;
  require sender != recipient;
  require ownerOf(token_id) == sender;
  require transferable() == true;

  mathint balance_sender_before = balanceOf(sender);
  mathint balance_recipient_before = balanceOf(recipient);

  transferFrom(e, sender, recipient, token_id);

  assert ownerOf(token_id) == recipient;
  assert balanceOf(sender) == balance_sender_before - 1;
  /* assert balanceOf(recipient) == balance_recipient_before + 1; */
}

rule transferNFT_invalidOwner {
  address sender;
  address recipient;
  uint token_id;

  env e;
  require e.msg.sender == sender;
  require sender != recipient;
  require ownerOf(token_id) != sender;
  require transferable() == true;

  transferFrom@withrevert(e, sender, recipient, token_id);
  assert lastReverted, "transfer should revert when the sender is not the owner of tokenId";
}

rule transferSoulbound {
  address sender;
  address recipient;
  uint token_id;

  env e;
  require e.msg.sender == sender;
  require sender != recipient;
  require ownerOf(token_id) == sender;
  require transferable() == false;

  mathint balance_sender_before = balanceOf(sender);
  mathint balance_recipient_before = balanceOf(recipient);

  transferFrom@withrevert(e, sender, recipient, token_id);

  assert lastReverted, "transfer should revert if it's a Soulbound token";
}

rule maxSupplyNotLowerThanTotalSupply(env e, method f) {
  calldataarg args;
  f(e, args); // call all public/external functions of a contract

  assert maxSupply() >= totalSupply();
}
