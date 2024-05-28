@description('The name of the Dev Center to create this catalog in')
param devCenterName string

@description('The name of the Catalog')
param catalogName string

@description('The URI of the repository to pull templates from')
param repoUri string

@description('The branch of the repository')
param branch string = 'main'

@description('The Key Vault used to retrieve the GitHub PAT token')
param keyVaultName string

@description('The GitHub PAT token')
@secure()
param patToken string

@description('The path of the repository where the catalog is located')
param path string = 'Environments'

resource devCenter 'Microsoft.DevCenter/devcenters@2024-05-01-preview' existing = {
  name: devCenterName
}

resource gitHubCatalog 'Microsoft.DevCenter/devcenters/catalogs@2024-05-01-preview' = {
  name: catalogName
  parent: devCenter
  properties: {
    gitHub: {
      branch: branch
      path: path
      uri: repoUri
      secretIdentifier: catalogPatToken.outputs.secretUri
    }
    syncType: 'Manual'
  }
}

module catalogPatToken '../security/key-vault-secret.bicep' = {
  name: '${deployment().name}-pat-toke'
  params: {
    tags: {
    }
    keyVaultName: keyVaultName
    secretName: '${devCenter.name}-pat-token'
    secretValue: patToken
  }
}
