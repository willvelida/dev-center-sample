@description('The name of the dev center project')
param devCenterName string

@description('The name of the Dev Center project')
param projectName string

@description('The Subscription ID of the deployment target. If not specified, the current subscription will be used')
param deploymentTargetId string = ''

@description('The name of the Environment Type')
param environmentTypeName string

@description('The location that the Environment Type will be deployed')
param location string

@description('The roles to assign to the environment type')
param roles string[] = []

@description('The members to give access to the project')
param members memberRoleAssignment[] = []

@description('The tags that will be applied to the Project Environment Type')
param tags object

type memberRoleAssignment = {
  user: string
  role: ('Deployment Environments User' | 'DevCenter Project Admin')
}

var builtInRoleMap = {
  owner: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
  contributor: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
  reader: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
}

var envTypeRoles = map(roles, (name) => { name: name, objectId: builtInRoleMap[toLower(name)] })

var roleMap = reduce(envTypeRoles, {}, (cur, next) => union(cur, {
      '${next.objectId}': {}
    }))

var subscriptionId = empty(deploymentTargetId) ? subscription().subscriptionId : deploymentTargetId
var ownerRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')

resource devCenter 'Microsoft.DevCenter/devcenters@2023-04-01' existing = {
  name: devCenterName
}

resource project 'Microsoft.DevCenter/projects@2023-04-01' existing = {
  name: projectName
}

resource environmentType 'Microsoft.DevCenter/projects/environmentTypes@2024-05-01-preview' =  {
  name: environmentTypeName
  location: location
  tags: tags
  parent: project
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    creatorRoleAssignment: {
      roles: roleMap
    }
    deploymentTargetId: '/subscriptions/${subscriptionId}'
    status: 'Enabled'
  }
}

module devCenterSubscriptionAccess 'subscription-access.bicep' = {
  name: '${deployment().name}-devcenter-subscription-access'
  scope: subscription(subscriptionId)
  params: {
    name: guid(devCenter.id, ownerRole, devCenter.identity.principalId)
    principalId: devCenter.identity.principalId
    roleDefinitionId: ownerRole
    principalType: 'ServicePrincipal'
  }
}

module environmentTypeSubscriptionAccess 'subscription-access.bicep' = {
  scope: subscription(subscriptionId)
  name: '${deployment().name}-subscription-access'
  params: {
    name: guid(environmentType.id, ownerRole, environmentType.identity.principalId)
    principalId: environmentType.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: ownerRole
  }
}

module memberAccess 'project-environment-type-access.bicep' = [for member in members: {
  name: '${deployment().name}-member-access-${uniqueString(project.name, environmentType.name, member.role, member.user)}'
  params: {
    environmentTypeName: environmentType.name
    principalId: member.user
    projectName: project.name
    role: member.role
  }
}] 
