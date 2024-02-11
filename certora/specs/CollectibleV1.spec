methods {
  function balanceOf(address) external returns (uint) envfree;
  function ownerOf(uint256 tokenId) external returns (address) envfree;
  function transferable() external returns (bool) envfree;
  function totalSupply() external returns (uint) envfree;
  function maxSupply() external returns (uint) envfree;
  function mintTo(address[]) external;
  function mintedCount() external returns (uint) envfree;
  function countAddressOccurrences(address[], address) external returns (uint) envfree;
  function _.onERC721Received(address, address, uint256, bytes) external => NONDET;
}

ghost mathint sumOfBalances {
    init_state axiom sumOfBalances == 0;
}

hook Sstore _balances[KEY address addr] uint256 newValue (uint256 oldValue) STORAGE {
    sumOfBalances = sumOfBalances - oldValue + newValue;
}

hook Sload uint256 balance _balances[KEY address addr] STORAGE {
    require sumOfBalances >= to_mathint(balance);
}

invariant mintCountGreaterEqualTotalSupplyAndTotalSupplyEqBalances()
    to_mathint(mintedCount()) >= to_mathint(totalSupply()) &&
      to_mathint(totalSupply()) == sumOfBalances;

rule integrityOfMintTo {
  requireInvariant mintCountGreaterEqualTotalSupplyAndTotalSupplyEqBalances();

  address[] addresses;
  env e;

  mathint totalSupply_before = totalSupply();
  mathint maxSupply = to_mathint(maxSupply());

  address addr;

  require totalSupply_before < maxSupply;
  require totalSupply_before + addresses.length <= maxSupply;

  mathint balance_addr_before = balanceOf(addr);
  mathint count = countAddressOccurrences(addresses, addr);
  mintTo(e, addresses);

  mathint totalSupply_after = totalSupply();
  mathint balance_addr_after = balanceOf(addr);

  assert totalSupply_after == totalSupply_before + addresses.length;
  assert balance_addr_after == balance_addr_before + count;
}


//rule integrityOfMintToWithEmptyArray{
//}


rule mintToReverts() {
  address[] addresses;
  env e;

  mathint supply_before = totalSupply();
  mathint max_supply = maxSupply();
  mathint minted_count = mintedCount();

  require supply_before <= max_supply;
  require minted_count >= supply_before;

  mintTo@withrevert(e, addresses);

  bool reverted = lastReverted;

  assert (supply_before + addresses.length > max_supply) => reverted;

  satisfy supply_before == max_supply && addresses.length > 0 && reverted;
}

rule mintToRelations() {
  address[] addresses_1;
  address[] addresses_2;
  env e;

  require addresses_1.length == 2;
  require addresses_1.length == addresses_2.length;

  require addresses_1[0] != addresses_1[1];
  require addresses_1[0] == addresses_2[1];
  require addresses_1[1] == addresses_2[0];

  mathint supply_before = totalSupply();
  mathint max_supply = maxSupply();
  mathint minted_count = mintedCount();

  require supply_before <= max_supply;
  require minted_count >= supply_before;

  address a;

  storage s1 = lastStorage;
  mintTo(e, addresses_1);
  mathint balance_s1 = balanceOf(a);

  mintTo(e, addresses_2) at s1;

  mathint balance_s2 = balanceOf(a);
  assert balance_s1 == balance_s2;
}

rule shouldPass {
  assert true;
}

/* rule sanity(env e, method f) { */
/*     calldataarg args; */
/*     f(e, args); */
/*     assert false; */
/* } */

/// rule mintTo_FromOwner {
///   // address owner;
///   address recipient_1;
///   address recipient_2;
///
///   env e;
///   require recipient_1 != recipient_2;
///   // require e.msg.sender == owner;
///   // require owner() == owner;
///   require maxSupply() == 100000;
///   require totalSupply() == 0;
///   require balanceOf(recipient_1) == 0;
///   require balanceOf(recipient_2) == 0;
///
///   assert balanceOf(recipient_1) == 0, "balance of recipient_1 should be 0";
///   assert balanceOf(recipient_2) == 0, "balance of recipient_2 should be 0";
///
///   mintTo(e, [recipient_1, recipient_2]);
///
///   assert balanceOf(recipient_1) == 1, "balance of recipient_1 should be 1";
///   assert balanceOf(recipient_2) == 1, "balance of recipient_2 should be 1";
/// }
///
/// rule transferNFT_validOwner {
///   address sender;
///   address recipient;
///   uint token_id;
///
///   env e;
///   require e.msg.sender == sender;
///   require sender != recipient;
///   require ownerOf(token_id) == sender;
///   require transferable() == true;
///
///   mathint balance_sender_before = balanceOf(sender);
///   mathint balance_recipient_before = balanceOf(recipient);
///
///   transferFrom(e, sender, recipient, token_id);
///
///   assert ownerOf(token_id) == recipient;
///   assert balanceOf(sender) == assert_uint256(balance_sender_before - 1);
///   /* assert balanceOf(recipient) == balance_recipient_before + 1; */
/// }
///
/// rule transferNFT_invalidOwner {
///   address sender;
///   address recipient;
///   uint token_id;
///
///   env e;
///   require e.msg.sender == sender;
///   require sender != recipient;
///   require ownerOf(token_id) != sender;
///   require transferable() == true;
///
///   transferFrom@withrevert(e, sender, recipient, token_id);
///   assert lastReverted, "transfer should revert when the sender is not the owner of tokenId";
/// }
///
/// rule transferSoulbound {
///   address sender;
///   address recipient;
///   uint token_id;
///
///   env e;
///   require e.msg.sender == sender;
///   require sender != recipient;
///   require ownerOf(token_id) == sender;
///   require transferable() == false;
///
///   mathint balance_sender_before = balanceOf(sender);
///   mathint balance_recipient_before = balanceOf(recipient);
///
///   transferFrom@withrevert(e, sender, recipient, token_id);
///
///   assert lastReverted, "transfer should revert if it's a Soulbound token";
/// }
///
/// rule maxSupplyNotLowerThanTotalSupply(env e, method f) {
///   require maxSupply() >= totalSupply();
///
///   calldataarg args;
///   f(e, args); // call all public/external functions of a contract
///
///   assert maxSupply() >= totalSupply();
/// }
