echo "deploy begin....."

TF_CMD=node_modules/.bin/truffle-flattener


# echo "" >  ./deployments/NFTMarket.full.sol
# cat  ./scripts/head.sol >  ./deployments/NFTMarket.full.sol
# $TF_CMD ./contracts/market/NFTMarket.sol >>  ./deployments/NFTMarket.full.sol 


# echo "" >  ./deployments/NFTMarketProxy.full.sol
# cat  ./scripts/head.sol >  ./deployments/NFTMarketProxy.full.sol
# $TF_CMD ./contracts/market/NFTMarketProxy.sol >>  ./deployments/NFTMarketProxy.full.sol 

# echo "" >  ./deployments/NFTRewardALPA1.full.sol
# cat  ./scripts/head.sol >  ./deployments/NFTRewardALPA1.full.sol
# $TF_CMD ./contracts/reward/NFTRewardALPA1.sol >>  ./deployments/NFTRewardALPA1.full.sol 

# echo "" >  ./deployments/NFTRewardALPA1Proxy.full.sol
# cat  ./scripts/head.sol >  ./deployments/NFTRewardALPA1Proxy.full.sol
# $TF_CMD ./contracts/reward/NFTRewardALPA1Proxy.sol >>  ./deployments/NFTRewardALPA1Proxy.full.sol 

# echo "" >  ./deployments/NFTRewardALPA2.full.sol
# cat  ./scripts/head.sol >  ./deployments/NFTRewardALPA2.full.sol
# $TF_CMD ./contracts/reward/NFTRewardALPA2.sol >>  ./deployments/NFTRewardALPA2.full.sol 

# echo "" >  ./deployments/NFTRewardALPA2Proxy.full.sol
# cat  ./scripts/head.sol >  ./deployments/NFTRewardALPA2Proxy.full.sol
# $TF_CMD ./contracts/reward/NFTRewardALPA2Proxy.sol >>  ./deployments/NFTRewardALPA2Proxy.full.sol 


# CONTRACT_LIST=(EXOArt EXOArtFactory EXOArtFactoryProxy)

# for contract in ${CONTRACT_LIST[@]};
# do
#     echo $contract
#     echo "" >  ./deployments/$contract.full.sol
#     cat  ./scripts/head.sol >  ./deployments/$contract.full.sol
#     $TF_CMD ./contracts/art/$contract.sol >>  ./deployments/$contract.full.sol 
# done


# $TF_CMD ./contracts/test/StorageProxy.sol >  ./deployments/StorageProxy.full.sol 
# $TF_CMD ./contracts/test/Storage.sol >  ./deployments/Storage.full.sol 

# echo "" >  ./deployments/MarsClaim.full.sol
# cat  ./scripts/head.sol >  ./deployments/MarsClaim.full.sol
# $TF_CMD ./contracts/mars/MarsClaim.sol >>  ./deployments/MarsClaim.full.sol 

# echo "" >  ./deployments/MarsClaimProxy.full.sol
# cat  ./scripts/head.sol >  ./deployments/MarsClaimProxy.full.sol
# $TF_CMD ./contracts/mars/ChristmasClaimProxy.sol >>  ./deployments/MarsClaimProxy.full.sol 

# echo "" >  ./deployments/EXOMarsClaimProxy.full.sol
# cat  ./scripts/head.sol >  ./deployments/EXOMarsClaimProxy.full.sol
# $TF_CMD ./contracts/mars/EXOMarsClaimProxy.sol >>  ./deployments/EXOMarsClaimProxy.full.sol 

# echo "" >  ./deployments/EXOMarsClaimProxyProxy.full.sol
# cat  ./scripts/head.sol >  ./deployments/EXOMarsClaimProxyProxy.full.sol
# $TF_CMD ./contracts/mars/EXOMarsClaimProxyProxy.sol >>  ./deployments/EXOMarsClaimProxyProxy.full.sol 

echo "" >  ./deployments/NFTMarketV2.full.sol
cat  ./scripts/head.sol >  ./deployments/NFTMarketV2.full.sol
$TF_CMD ./contracts/market/NFTMarketV2.1.sol >>  ./deployments/NFTMarketV2.full.sol 

# rm *_sol_*

echo "deploy end....."
