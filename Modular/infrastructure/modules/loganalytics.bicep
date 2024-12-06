param location string = resourceGroup().location
@minLength(6)
param logAnalyticsName string
param envName string

// Deploy resource
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: (envName == 'dev') ? 30 : 90
  }
}
