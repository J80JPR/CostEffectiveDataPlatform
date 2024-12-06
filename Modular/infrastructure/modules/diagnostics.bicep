param azureKeyVaultName string
param azureDataLakeStoreAccountName string
param logAnalyticsName string
param azureSqlServerName string
param azureSqlDatabaseName string
param eventHubNameSpaceName string
param azureDataFactoryName string
// param azureDatabricksName string

// Lookup needed resources
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsName
}

// Turn on Diagnostics
// SQL DB
resource sqlDB 'Microsoft.Sql/servers/databases@2024-05-01-preview' existing = {
  name: '${azureSqlServerName}/${azureSqlDatabaseName}' // Must use full path for existing nested resources
}
resource sqlDBDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: sqlDB
  name: 'logs-${azureSqlDatabaseName}'
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// Key vault
resource akv 'Microsoft.KeyVault/vaults@2024-04-01-preview' existing = {
  name: azureKeyVaultName
}
resource akvDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: akv
  name: 'logs-${azureKeyVaultName}'
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// Event Hub
resource eventHubNamespace 'Microsoft.EventHub/namespaces@2024-05-01-preview' existing = {
  name: eventHubNameSpaceName
}
resource eventHubDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: eventHubNamespace
  name: 'logs-${eventHubNameSpaceName}'
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// ADLS
resource adlsAccountBlobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' existing = {
  name: '${azureDataLakeStoreAccountName}/default' // Must use 'default' as the blob service name as it's a nested resource
}
resource adlsDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: adlsAccountBlobService
  name: 'logs-${azureDataLakeStoreAccountName}-blob'
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// Data factory
resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: azureDataFactoryName
}
resource adfDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: dataFactory
  name: 'logs-${azureDataFactoryName}'
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// Databricks
// resource databricksWorkspace 'Microsoft.Databricks/workspaces@2024-05-01' existing = {
//   name: azureDatabricksName
// }
// resource Diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
//   scope: databricksWorkspace
//   name: 'logs-${azureDatabricksName}'
//   properties: {
//     workspaceId: logAnalyticsWorkspace.id
//     logAnalyticsDestinationType: 'Dedicated'
//     logs: [
//       {
//         categoryGroup: 'allLogs'
//         enabled: true
//         retentionPolicy: {
//           enabled: true
//           days: 30
//         }
//       }
//     ]
//     // metrics: [
//     //   {
//     //     category: 'AllMetrics'
//     //     enabled: true
//     //     retentionPolicy: {
//     //       enabled: true
//     //       days: 30
//     //     }
//     //   }
//     // ]
//   }
// }
