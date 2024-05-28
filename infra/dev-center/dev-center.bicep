@description('The name of the Dev Center that will be deployed')
@minLength(3)
@maxLength(26)
param devCenterName string

@description('The location where all resources will be deployed. Default is the location of the resource group.')
param location string

@description('The configuration for the dev center')
param config devCenterConfig

@description('The Subscription ID of the deployment target. If not specified, the current subscription will be used')
param deploymentTargetId string = ''

@description('The name of the Log Analytics workspace that this Dev Center will send logs to')
param logAnalyticsName string

@description('The principal id to add as a admin of the dev center')
param principalId string = ''

@description('The name of the Key Vault')
param keyVaultName string

@description('The GitHub PAT token')
@secure()
param patToken string = ''

@description('The tags that will be applied to all resources in the Dev Center')
param tags object

var ownerRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')
var subscriptionId = empty(deploymentTargetId) ? subscription().subscriptionId : deploymentTargetId
var defaultProjectRoleAssignments = {
  user: principalId
  role: 'DevCenter Project Admin'
}

type devCenterConfig = {
  orgName: string
  projects: project[]
  catalogs: catalog[]
  environmentTypes: devCenterEnvironmentType[]
}

type project = {
  name: string
  environmentTypes: projectEnvironmentType[]
  members: memberRoleAssignment[]
}

type catalog = {
  name: string
  repo: string
  branch: string?
  path: string?
  secretIdentifier: string?
}

type devCenterEnvironmentType = {
  name: string
  tags: object?
}

type projectEnvironmentType = {
  name: string
  deploymentTargetId: string?
  tags: object?
  roles: string[]
  members: memberRoleAssignment[]
}

type memberRoleAssignment = {
  user: string
  role: ('Deployment Environments User' | 'DevCenter Project Admin')
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsName
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource devCenter 'Microsoft.DevCenter/devcenters@2024-05-01-preview' = {
  name: devCenterName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
}

resource devCenterLogs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: devCenter.name
  scope: devCenter
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      { 
        enabled: true
        categoryGroup: 'allLogs'
      }
      { 
        enabled: true
        categoryGroup: 'audit'
      }
    ]
  }
}

module devCenterSubscriptionAccess 'subscription-access.bicep' = {
  scope: subscription(subscriptionId)
  name: '${deployment().name}-devcenter-subscription-access'
  params: {
    name: guid(devCenter.id, ownerRole, devCenter.identity.principalId)
    principalId: devCenter.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: ownerRole
  }
}

module devCenterEnvType 'dev-center-environment-type.bicep' = [for envType in config.environmentTypes: {
  name: '${deployment().name}-${envType.name}'
  params: {
    devCenterName: devCenter.name
    name: envType.name
    tags: empty(envType.tags) ? {} : envType.tags
  }
}]

module devCenterProject 'project.bicep' = [for project in config.projects: {
  name: '${deployment().name}-${project.name}'
  params: {
    devCenterName: devCenter.name
    environmentTypes: project.environmentTypes
    location: location
    members: !empty(project.members) ? project.members : [defaultProjectRoleAssignments]
    projectName: project.name
    tags: tags
  }
}]

module devCenterCatalog 'github-catalog.bicep' = [for catalog in config.catalogs: {
  name: '${deployment().name}-${catalog.name}'
  params: {
    catalogName: catalog.name
    devCenterName: devCenter.name
    repoUri: catalog.repo
    path: catalog.path
    branch: catalog.branch
    keyVaultName: keyVault.name
    patToken: patToken
  }
}]

module devCenterKeyVaultAccess '../security/key-vault-access.bicep' = {
  name: '${deployment().name}-kv-access'
  params: {
    keyVaultName: keyVault.name
    principalId: devCenter.identity.principalId
  }
}

@description('The name of the created Dev Center')
output name string = devCenter.name
