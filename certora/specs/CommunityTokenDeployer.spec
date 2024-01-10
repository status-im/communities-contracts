using CommunityOwnerTokenRegistry as CommunityOwnerTokenRegistry;

methods {
  function owner() external returns (address) envfree;
  function deploymentRegistry() external returns (address) envfree;
  function ownerTokenFactory() external returns (address) envfree;
  function masterTokenFactory() external returns (address) envfree;
  function deploy(CommunityTokenDeployer.TokenConfig, CommunityTokenDeployer.TokenConfig, CommunityTokenDeployer.DeploymentSignature, bytes) external returns (address, address);

  function CommunityOwnerTokenRegistry.getEntry(address) external returns (address) envfree;
  function CommunityOwnerTokenRegistry.tokenDeployer() external returns (address) envfree;


  function _.balanceOf(address _owner) external => DISPATCHER(true);
}

rule integrityOfDeploy {

  env e;
  CommunityTokenDeployer.TokenConfig ownerToken;
  CommunityTokenDeployer.TokenConfig masterToken;
  CommunityTokenDeployer.DeploymentSignature signature;
  bytes signerPublicKey;

  deploy(e, ownerToken, masterToken, signature, signerPublicKey);

  address tokenAddress = CommunityOwnerTokenRegistry.getEntry(signature.signer);
  assert tokenAddress != 0;
}

rule registryMutability(method f) {
  env e;
  CommunityTokenDeployer.DeploymentSignature signature;
  calldataarg args;

  address tokenAddressBefore = CommunityOwnerTokenRegistry.getEntry(signature.signer);
  require tokenAddressBefore != 0;

  f(e, args);

  address tokenAddressAfter = CommunityOwnerTokenRegistry.getEntry(signature.signer);
  assert tokenAddressBefore == tokenAddressAfter;
}

rule registryChange(method f) {
  env e;
  calldataarg args;

  address registryBefore = deploymentRegistry();
  f(e, args);
  address registryAfter = deploymentRegistry();

  assert registryBefore != registryAfter => e.msg.sender == owner();
}

rule ownerTokenFactoryChange(method f) {
  env e;
  calldataarg args;

  address factoryBefore = ownerTokenFactory();
  f(e, args);
  address factoryAfter = ownerTokenFactory();

  assert factoryBefore != factoryAfter => e.msg.sender == owner();
}

rule masterTokenFactoryChange(method f) {
  env e;
  calldataarg args;

  address factoryBefore = masterTokenFactory();
  f(e, args);
  address factoryAfter = masterTokenFactory();

  assert factoryBefore != factoryAfter => e.msg.sender == owner();
}
