@description('The name of the Virtual Network')
param vnetName string

@description('The name for the Dev Center Subnet')
param subnetName string

@description('The location where the Virtual Network will be deployed')
param location string

@description('The name of the Dev Center to create the network connection')
param devCenterName string

@description('The tags that will be applied to the Virtual Network')
param tags object

@description('The Address Prefixes for the Virtual Network')
param vnetAddress string = '10.0.0.0/16'

@description('The Address Prefix for the subnet')
param subnetAddress string = '10.0.0.0/24'

@description('The name of a new resource group that will be created to store some Networking resources (like NICs) in')
param networkingResourceGroupName string = '${resourceGroup().name}-networking-${location}'

resource devCenter 'Microsoft.DevCenter/devcenters@2024-05-01-preview' existing = {
  name: devCenterName
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddress
      ]
    }
    subnets: [
      { 
        name: subnetName
        properties: {
          addressPrefix: subnetAddress
        }
      }
    ]
  }

  resource devCenterSubnet 'subnets' existing = {
    name: subnetName
  }
}

resource networkConnection 'Microsoft.DevCenter/networkConnections@2024-05-01-preview' = {
  name: 'con-${devCenterName}-${vnet.name}'
  location: location
  properties: {
    domainJoinType: 'AzureADJoin'
    subnetId: vnet::devCenterSubnet.id
    networkingResourceGroupName: networkingResourceGroupName
  }
}

resource attachedNetwork 'Microsoft.DevCenter/devcenters/attachednetworks@2024-05-01-preview' = {
  name: 'dcon-${devCenter.name}-${vnet.name}'
  parent: devCenter
  properties: {
    networkConnectionId: networkConnection.id
  }
}
