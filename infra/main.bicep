@description('The location where all resources will be deployed. Default is the location of the resource group.')
param location string = resourceGroup().location

@description('The name of the Dev Center that will be deployed')
@minLength(3)
@maxLength(26)
param devCenterName string

@description('The name of the Log Analytics workspace that will be deployed')
param logAnalyticsName string

@description('The name of the Virtual Network that will be created')
param vnetName string

@description('The name of the subnet that will be created for Dev Center')
param subnetName string

@description('The name of the Key Vault that will be deployed')
param keyVaultName string

@description('The PAT token to access the catalog')
@secure()
param catalogToken string = ''

@description('The Principal ID of the user or app to assign app roles to.')
param principalId string

@description('The tags that will be applied to all resources.')
param tags object

var devCenterConfig = loadYamlContent('devcenter.yaml')

module logAnalytics 'monitor/log-analytics.bicep' = {
  name: 'law'
  params: {
    location: location
    logAnalyticsName: logAnalyticsName
    tags: tags
  }
}

module devCenter 'dev-center/dev-center.bicep' = {
  name: 'dev-center'
  params: {
    devCenterName: devCenterName
    location: location
    logAnalyticsName: logAnalytics.outputs.name
    tags: tags
    config: devCenterConfig
    keyVaultName: keyVault.outputs.name
    patToken: catalogToken
  }
}

module vnet 'networking/virtual-network.bicep' = {
  name: 'vnet'
  params: {
    devCenterName: devCenter.outputs.name
    location: location
    subnetName: subnetName
    tags: tags
    vnetName: vnetName
  }
}

module keyVault 'security/key-vault.bicep' = if(!empty(catalogToken)) { 
  name: 'keyvault'
  params: {
    location: location
    tags: tags
    keyVaultName: keyVaultName
    principalId: principalId
    permissions: {
      secrets: [
        'get'
        'list'
        'set'
        'delete'
      ]
    }
  }
}
