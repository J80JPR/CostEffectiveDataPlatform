param location string = resourceGroup().location
@minLength(6)
param azureSqlDatabaseName string
@minLength(6)
param azureSqlServerName string

// Lookup needed resources
resource sqlServer 'Microsoft.Sql/servers@2024-05-01-preview' existing = {
  name: azureSqlServerName
}

// Deploy resource
resource sqlDB 'Microsoft.Sql/servers/databases@2024-05-01-preview' = {
  parent: sqlServer
  name: azureSqlDatabaseName
  location: location
  sku: {
    capacity: 5
    name: 'Basic'
    tier: 'Basic'
  }
}
