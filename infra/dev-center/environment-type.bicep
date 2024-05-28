@description('The Dev Center that this ADE will be deployed to')
param devCenterName string

@description('The name of the Azure Deployment Environment that will be created')
param environmentName string[]

@description('The tags that will be applied to the environment type')
param tags object

resource devCenter 'Microsoft.DevCenter/devcenters@2022-11-11-preview' existing = {
  name: devCenterName
}

resource env 'Microsoft.DevCenter/devcenters/environmentTypes@2024-05-01-preview' = [for name in environmentName: {
  name: name
  parent: devCenter
  tags: tags
}]
