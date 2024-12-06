extension microsoftGraphV1

param location string = resourceGroup().location
@minLength(6)
param azureDataLakeStoreAccountName string
param securityGroupName string
param securityGroupid string
param envName string

// Obtain resource details for built-in roles
@description('This is the built-in Storage Blob Data Contributor role')
resource sbdcRoleDefinitionResourceId 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: subscription()
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}

// Deploy resource
resource adlsAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: azureDataLakeStoreAccountName
  location: location
  sku: { name: 'Standard_GRS' }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    isHnsEnabled: true
    accessTier: 'Hot'
  }
  identity: { type: 'SystemAssigned' }
}

// Configure resource
resource adlsAccountBlobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: adlsAccount
  name: 'default'
  properties: {
    // Set retention periods based on environment
    containerDeleteRetentionPolicy: {
      enabled: true
      days: (envName == 'dev') ? 15 : 30
    }
    deleteRetentionPolicy: {
      enabled: true
      days: (envName == 'dev') ? 15 : 30
    }
  }
}

// Create containers

var containers = {
  bronze: {
    name: 'raw'
  }
  silver: {
    name: 'cleansed'
  }
  gold: {
    name: 'curated'
  }
}

resource adlsAccountContainers 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = [
  for container in items(containers): {
    parent: adlsAccountBlobService
    name: container.value.name
  }
]

// Assign permissions
@description('Assigns the Admin Group to Storage Blob Data Contributor Role')
resource userRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: adlsAccount
  name: guid(adlsAccount.id, securityGroupName, sbdcRoleDefinitionResourceId.id)
  properties: {
    roleDefinitionId: sbdcRoleDefinitionResourceId.id
    principalId: securityGroupid
  }
}
