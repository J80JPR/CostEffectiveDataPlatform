extension microsoftGraphV1

param location string = resourceGroup().location
@minLength(6)
param azureSqlServerName string
param sqlAdministratorLogin string
@secure()
param sqlAdministratorPassword string
param securityGroupName string
param securityGroupid string

// Lookup needed resources
// resource securityGroup 'Microsoft.Graph/groups@v1.0' existing = {
//   uniqueName: securityGroupName
// }

// Deploy resource
resource sqlServer 'Microsoft.Sql/servers@2024-05-01-preview' = {
  name: azureSqlServerName
  location: location
  properties: {
    minimalTlsVersion: '1.2'
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlAdministratorPassword
    administrators: {
      administratorType: 'ActiveDirectory'
      azureADOnlyAuthentication: false
      login: securityGroupName
      sid: securityGroupid
      tenantId: subscription().tenantId
    }
  }
}

// Configure resource
resource sqlServerFirewallRules 'Microsoft.Sql/servers/firewallRules@2024-05-01-preview' = {
  parent: sqlServer
  name: 'Allow Azure Services'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}
