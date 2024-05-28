@description('The name of the Log Analytics workspace that will be deployed')
param logAnalyticsName string

@description('The location where the Log Analytics workspace will be deployed')
param location string

@description('The tags that will be applied to the Log Analytics Workspace')
param tags object

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    workspaceCapping: {
      dailyQuotaGb: 5
    }
  }
}

@description('The name of the Log Analytics Workspace')
output name string = logAnalytics.name
