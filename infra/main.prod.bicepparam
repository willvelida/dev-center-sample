using 'main.bicep'

param devCenterName = 'wv-devcenter-prod'
param logAnalyticsName = 'wv-law-prod'
param vnetName = 'wv-vnet-prod'
param keyVaultName = 'wv-kv-prod'
param principalId = ''
param catalogToken = ''
param subnetName = 'subnet-devpools'
param tags = {
  Owner: 'Will Velida'
  Environment: 'Production'
}
