@description('The name of the Dev Center this project will be associated with')
param devCenterName string

@description('The Name of the Project associated with the Dev Center')
@minLength(3)
@maxLength(26)
param projectName string

@description('The location where the Project will be deployed')
param location string

@description('The environment types to create')
param environmentTypes environmentType[]

@description('The members to give access to the project')
param members memberRoleAssignment[]

@description('The tags that will be applied to the Project')
param tags object

var defaultEnvironmentTypeRoles = [ 'Owner' ]

type environmentType = {
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

resource devCenter 'Microsoft.DevCenter/devcenters@2024-05-01-preview' existing = {
  name: devCenterName
}

resource project 'Microsoft.DevCenter/projects@2024-05-01-preview' = {
  name: projectName
  location: location
  tags: tags
  properties: {
    devCenterId: devCenter.id
  }
}

module projectEnvType 'project-environment-type.bicep' = [for envType in environmentTypes: {
  name: envType.name
  params: {
    devCenterName: devCenter.name
    environmentTypeName: envType.name
    location: location
    projectName: project.name
    tags: tags
    roles: !empty(envType.roles) ? envType.roles : defaultEnvironmentTypeRoles
    members: !empty(envType.members) ? envType.members : []
  }
}]

module memberAccess 'project-access.bicep' = [for member in members: {
  name: '${deployment().name}-member-access-${uniqueString(project.name, member.role, member.user)}'
  params: {
    principalId: member.user
    projectName: project.name
    role: member.role
  }
}]
