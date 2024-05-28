@description('The name of the Key Vault Secret')
param secretName string

@description('The Key Vault to store the secret')
param keyVaultName string

@description('The value of the secret.')
@secure()
param secretValue string

@description('Is the secret enabled? Default set to true')
param isEnabled bool = true

@description('The expiry date of the secret')
param expiryDate int = 0

@description('The not-before date of the secret')
param notBefore int = 0

@description('The content type of the secret')
param contentType string = 'string'

@description('The tags that will be applied to the Key Vault secret')
param tags object

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource keyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: secretName
  tags: tags
  parent: keyVault
  properties: {
    attributes: {
      enabled: isEnabled
      exp: expiryDate
      nbf: notBefore
    }
    value: secretValue
    contentType: contentType
  }
}

@description('The Id of the Secret')
output secretIdentifier string = keyVaultSecret.id

@description('The Uri of the Secret')
output secretUri string = keyVaultSecret.properties.secretUri
