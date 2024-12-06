extension microsoftGraphV1

param location string = resourceGroup().location
@minLength(6)
param azureKeyVaultName string
param securityGroupName string
param securityGroupid string
@secure()
param sqlAdministratorPassword string

// Obtain resource details for built-in roles
var akvRoleName = 'Key Vault Secrets User'

var akvRoleIdMapping = {
  'Key Vault Secrets User': '4633458b-17de-408a-b874-0445c86b69e6'
}

// Deploy resource
resource akv 'Microsoft.KeyVault/vaults@2024-04-01-preview' = {
  name: azureKeyVaultName
  location: location
  properties: {
    enableRbacAuthorization: true
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: subscription().tenantId
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// Assign permissions
@description('Assigns the Admin Group to Azure Key Vault Role Key Vault Secrets User')
resource userAkvRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(akvRoleIdMapping[akvRoleName], securityGroupName, akv.id)
  scope: akv
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', akvRoleIdMapping[akvRoleName])
    principalId: securityGroupid
  }
}

resource sqlPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2024-04-01-preview' = {
  parent: akv
  name: 'sqlAdminPassword'
  properties: {
    value: sqlAdministratorPassword
  }
}
