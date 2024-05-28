@description('The name of the Key Vault to apply the access policy to')
param keyVaultName string

@description('The permissions to apply to the Key Vault')
param permissions object = {
  secrets: [ 'get', 'list']
}

@description('The principal ID to grant the secrets to')
param principalId string

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource keyVaultAccessPolicies 'Microsoft.KeyVault/vaults/accessPolicies@2023-07-01' = {
  name: 'add'
  parent: keyVault
  properties: {
    accessPolicies: [{
      objectId: principalId
      tenantId: subscription().tenantId
      permissions: permissions
    }]
  }
}
