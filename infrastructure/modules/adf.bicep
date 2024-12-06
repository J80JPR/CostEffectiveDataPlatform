param location string = resourceGroup().location
@minLength(6)
param azureDataFactoryName string
param envName string
param azureDataLakeStoreAccountName string
param azureKeyVaultName string
param sqlAdministratorLogin string
@secure()
param sqlAdministratorPassword string
param databricksWorkspaceName string

// Obtain resource details for built-in roles
var akvRoleName = 'Key Vault Secrets User'

var akvRoleIdMapping = {
  'Key Vault Secrets User': '4633458b-17de-408a-b874-0445c86b69e6'
}

@description('This is the built-in Contributor role for Databricks')
var adbContributorRoleId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

@description('This is the built-in Storage Blob Data Contributor role')
resource sbdcRoleDefinitionResourceId 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: subscription()
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}

// Lookup needed resources
resource akv 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: azureKeyVaultName
}

resource adlsAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: azureDataLakeStoreAccountName
}

resource databricksWorkspace 'Microsoft.Databricks/workspaces@2023-02-01' existing = {
  name: databricksWorkspaceName
}

// Deploy resource
resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: azureDataFactoryName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    globalParameters: {
      envName: {
        type: 'String'
        value: envName
      }
    }
  }
}

// Configure resource

// Add Linked Services
resource adlsLinkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  parent: dataFactory
  name: 'LS_DataLake_MIAuth'
  properties: {
    type: 'AzureBlobFS'
    parameters: {
      storageName: {
        type: 'String'
      }
    }
    typeProperties: {
      accountKey: adlsAccount.listKeys().keys[0].value
      url: 'https://@{linkedService().storageName}.dfs.${environment().suffixes.storage}'
    }
  }
}

resource azureSqlDatabaseLinkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  parent: dataFactory
  name: 'LS_SQLDB_MIAuth'
  properties: {
    type: 'AzureSqlDatabase'
    parameters: {
      serverName: {
        type: 'String'
      }
      databaseName: {
        type: 'String'
      }
    }
    typeProperties: {
      connectionString: 'Data Source=@{linkedService().serverName}${environment().suffixes.sqlServerHostname};Initial Catalog=@{linkedService().databaseName};User ID=${sqlAdministratorLogin};Password=${sqlAdministratorPassword};'
    }
  }
}

resource azureKeyVaultLinkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  parent: dataFactory
  name: 'LS_KeyVault_MIAuth'
  properties: {
    type: 'AzureKeyVault'
    typeProperties: {
      baseUrl: akv.properties.vaultUri
    }
  }
}

resource databricksLinkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  parent: dataFactory
  name: 'LS_Databricks_MIAuth'
  properties: {
    type: 'AzureDatabricks'
    typeProperties: {
      domain: 'https://${databricksWorkspace.properties.workspaceUrl}'
      authentication: 'MSI'
      workspaceResourceId: databricksWorkspace.id
    }
  }
}

// Add datasets
resource sqlTableDataset 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  parent: dataFactory
  name: 'DS_SQLDB_MIAuth'
  properties: {
    linkedServiceName: {
      referenceName: azureSqlDatabaseLinkedService.name
      type: 'LinkedServiceReference'
      parameters: {
        databaseName: {
          value: '@dataset().databaseName'
          type: 'Expression'
        }
        serverName: {
          value: '@dataset().serverName'
          type: 'Expression'
        }
      }
    }
    parameters: {
      serverName: {
        type: 'string'
      }
      databaseName: {
        type: 'string'
      }
      schemaName: {
        type: 'string'
      }
      tableName: {
        type: 'string'
      }
    }
    type: 'AzureSqlTable'
    typeProperties: {
      schema: '@dataset().schemaName'
      table: '@dataset().tableName'
    }
  }
}


resource parquetDataset 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  parent: dataFactory
  name: 'DS_DataLake_Parquet'
  properties: {
    linkedServiceName: {
      referenceName: adlsLinkedService.name
      type: 'LinkedServiceReference'
      parameters: {
        storageName: {
          value: '@dataset().storageName'
          type: 'Expression'
        }
      }
    }
    parameters: {
      storageName: {
        type: 'string'
      }
      container: {
        type: 'string'
      }
      directory: {
        type: 'string'
      }
      fileName: {
        type: 'string'
      }
    }
    type: 'Parquet'
    typeProperties: {
      location: {
        type: 'AzureBlobFSLocation'
        fileName: '@dataset().fileName'
        folderPath: '@dataset().directory'
        fileSystem: '@dataset().container'
      }
    }
  }
}

resource delimitedTextDataset 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  parent: dataFactory
  name: 'DS_DataLake_TextDelimited'
  properties: {
    linkedServiceName: {
      referenceName: adlsLinkedService.name
      type: 'LinkedServiceReference'
      parameters: {
        storageName: {
          value: '@dataset().storageName'
          type: 'Expression'
        }
      }
    }
    parameters: {
      storageName: {
        type: 'string'
      }
      container: {
        type: 'string'
      }
      directory: {
        type: 'string'
      }
      fileName: {
        type: 'string'
      }
      columnDelimiter: {
        type: 'string'
        defaultValue: ','
      }
    }
    type: 'DelimitedText'
    typeProperties: {
      location: {
        type: 'AzureBlobFSLocation'
        fileName: '@dataset().fileName'
        folderPath: '@dataset().directory'
        fileSystem: '@dataset().container'
      }
      columnDelimiter: '@dataset().columnDelimiter'
      firstRowAsHeader: true
    }
  }
}

resource deltaLakeDataset 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  parent: dataFactory
  name: 'DS_DataLake_Delta'
  properties: {
    linkedServiceName: {
      referenceName: databricksLinkedService.name
      type: 'LinkedServiceReference'
    }
    parameters: {
      database: {
        type: 'string'
      }
      table: {
        type: 'string'
      }
    }
    type: 'AzureDatabricksDeltaLakeDataset'
    typeProperties: {
      database: {
        value: '@dataset().database'
        type: 'Expression'
      }
      table: {
        value: '@dataset().table'
        type: 'Expression'
      }
    }
  }
}


// assign permissions
@description('Assigns the ADF Managed Identity to Storage Blob Data Contributor Role')
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: adlsAccount
  name: guid(adlsAccount.id, dataFactory.id, sbdcRoleDefinitionResourceId.id)
  properties: {
    roleDefinitionId: sbdcRoleDefinitionResourceId.id
    principalId: dataFactory.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

@description('Assigns the ADF Managed Identity to Azure Key Vault Role Key Vault Secrets User')
resource spAkvRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(akvRoleIdMapping[akvRoleName], dataFactory.id, akv.id)
  scope: akv
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', akvRoleIdMapping[akvRoleName])
    principalId: dataFactory.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

@description('Assigns the ADF Managed Identity to Azure Databricks')
resource adfDatabricksRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: databricksWorkspace
  name: guid(databricksWorkspace.id, dataFactory.id, adbContributorRoleId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', adbContributorRoleId)
    principalId: dataFactory.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
