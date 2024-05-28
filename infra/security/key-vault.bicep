@description('The name of the Key Vault')
param keyVaultName string

@description('The location where the Key Vault will be deployed')
param location string

@description('The tags that will be applied to the Key Vault')
param tags object

@description('The principal Id that will be given access to this Key Vault')
param principalId string = ''

@description('The Key Vault permissions that will be granted to the Principal Id')
param permissions object = {}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A' 
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enabledForTemplateDeployment: true
    accessPolicies: [
      { 
        objectId: principalId
        permissions: empty(permissions) ? { secrets: ['get', 'list']} : permissions
        tenantId: subscription().tenantId
      }
    ]
  }
}

@description('The name of the created key vault')
output name string = keyVault.name

@description('The endpoint for the created key vault')
output endpoint string = keyVault.properties.vaultUri
