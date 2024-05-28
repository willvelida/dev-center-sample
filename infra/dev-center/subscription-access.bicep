targetScope = 'subscription'

@description('The role assignment name')
param name string

@description('The Principal ID for the role assignment')
param principalId string

@description('The Principal type for the role assignment')
param principalType ('User' | 'Group' | 'ServicePrincipal')

@description('The role definition ID for the role assignment')
param roleDefinitionId string

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: name
  properties: {
    principalId: principalId 
    roleDefinitionId: roleDefinitionId
    principalType: principalType
  }
}
