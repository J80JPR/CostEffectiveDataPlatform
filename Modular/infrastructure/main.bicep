extension microsoftGraphV1

targetScope = 'subscription'

var securityGroupName = 'CF.CumulusAdmins'

// resource securityGroup 'Microsoft.Graph/groups@v1.0' existing = {
//   uniqueName: securityGroupName
// }

// var securityGroupid = securityGroup.id

var securityGroupid = '2ff88481-d099-4c45-8cfa-6f8d9503a6bc'

@description('Fixed timestamp to append to deployments')
param deploymentTimestamp string = utcNow('yy-MM-dd-HHmm')

@description('Which environment are you deploying to (dev, tst or prd)?')
@allowed(['dev', 'tst', 'prd'])
param envName string = 'dev'

@description('Workload prefix')
@minLength(3)
@maxLength(4)
param workloadName string = 'cedp'

@description('Organization name')
param orgName string = 'dq'

@description('Unique suffix for resource names')
param uniqueIdentifier string = '001'

@description('Azure region for deployment')
param location string = 'uksouth'

@description('Do you want to deploy a new Azure Event Hub for streaming use cases (true or false)?')
param optionalDeployEventHub bool = true

@description('Do you want to deploy a new Azure SQL Server (true or false)?')
param optionalDeploySqlServer bool = true

@description('Do you want to deploy a new Azure SQL Database (true or false)?')
param optionalDeploySqlDb bool = true

@description('Do you want to deploy Azure Data Factory (true or false)?')
param optionalDeployADF bool = true

@description('Do you want to deploy Azure Databricks Workspace(true or false)?')
param optionalDeployADBWorkspace bool = true

@description('Do you want to enable No Public IP (NPIP) for your Azure Databricks workspace (true or false)?')
param databricksNPIP bool = true

// @description('Do you want to deploy Azure Databricks Cluster(true or false)?')
// param deployADBCluster bool = true

// These variables control resource naming and deployment options, required for consistent resource naming across environments

@description('Mapping of Azure regions to short codes for naming conventions')
var regionAbbreviations = {
  uksouth: 'uks'
  ukwest: 'ukw'
  eastus: 'eus'
  westus: 'wus'
  westus2: 'wus2'
  centralus: 'cus'
  northcentralus: 'ncus'
  southcentralus: 'scus'
  eastus2: 'eus2'
  westeurope: 'weu'
  northeurope: 'neu'
  francecentral: 'frc'
  germanywestcentral: 'gwc'
  switzerlandnorth: 'swn'
  norwayeast: 'noe'
  brazilsouth: 'brs'
  canadacentral: 'cac'
  canadaeast: 'cae'
}

var locationShortCode = regionAbbreviations[location]

@description('Mapping of Resources to short codes for naming conventions')
var resourceShortCodes = {
  storageV1: 'st'
  storageV2: 'dl'
  resourcegroup: 'rg'
  azureDataFactory: 'adf'
  databricksWorkspace: 'dbw'
  eventHub: 'eh'
  eventHubNameSpace: 'ehns'
  keyVault: 'kv'
  sqlServer: 'sql'
  sqlDatabase: 'sqldb'
  managedResourceGroup: 'rgm'
  loganalytics: 'la'
}

// Resource naming convention variables
var namePrefix = '${workloadName}${orgName}${envName}'
var nameSuffix = '${locationShortCode}${uniqueIdentifier}'

@description('''Name of the Resource Group''')
var rgName = '${namePrefix}${resourceShortCodes.resourcegroup}${nameSuffix}'

@description('''Name of the Log Analytics Workspace''')
var logAnalyticsName = '${namePrefix}${resourceShortCodes.loganalytics}${nameSuffix}'

@description('''Name of the Azure Data Lake Storage Gen2 storage account.''')
var azureDataLakeStoreAccountName = '${namePrefix}${resourceShortCodes.storageV2}${nameSuffix}'

@description('Name of the Azure Data Factory instance.')
var azureDataFactoryName = '${namePrefix}${resourceShortCodes.azureDataFactory}${nameSuffix}'

@description('''Name of the Azure Databricks workspace.''')
var databricksWorkspaceName = '${namePrefix}${resourceShortCodes.databricksWorkspace}${nameSuffix}'

@description('''Name of the Azure Databricks Managed workspace.''')
var azureDatabricksManagedName = '${namePrefix}${resourceShortCodes.managedResourceGroup}${nameSuffix}'

@description('''Name of the Azure Event Hub.''')
var eventHubName = '${namePrefix}${resourceShortCodes.eventHub}${nameSuffix}'

@description('''Name of the Azure Event Hub NameSpace.''')
var eventHubNameSpaceName = '${namePrefix}${resourceShortCodes.eventHubNameSpace}${nameSuffix}'

@description('''Name of the Azure Key Vault.''')
var azureKeyVaultName = '${namePrefix}${resourceShortCodes.keyVault}${nameSuffix}'

@description('Name of Azure SQL logical server')
var azureSqlServerName = '${namePrefix}${resourceShortCodes.sqlServer}${nameSuffix}'

@description('Name of Azure SQL Database')
var azureSqlDatabaseName = '${namePrefix}${resourceShortCodes.sqlDatabase}${nameSuffix}'

@description('Name for SQL Administrator Login')
var sqlAdministratorLogin = 'sqladmin'

param randomGuid string = newGuid()
var specialChars = '!@#$%^&*' // Special characters to be used in the password
@description('Password for SQL Administrator Login')
var sqlAdministratorPassword = '${take(randomGuid, 16)}${take(specialChars, 2)}1A'

// Create security group - not allowed in BICEP currently

// resource createSecurityGroup 'Microsoft.Graph/groups@v1.0' = {
//   displayName: securityGroupName
//   mailEnabled: false
//   mailNickname: securityGroupName
//   securityEnabled: true
//   uniqueName: securityGroupName
//   theme: 'Red'
// }

// Create Resource group
resource rg 'Microsoft.Resources/resourceGroups@2024-07-01' = {
  name: rgName
  location: location
}

//Deploy Resources
module DeployLogAnalytics './modules/loganalytics.bicep' = {
  scope: rg
  name: 'loganalytics${deploymentTimestamp}'
  params: {
    logAnalyticsName: logAnalyticsName
    envName: envName
  }
  dependsOn: []
}

module DeployKeyVault './modules/keyvault.bicep' = {
  scope: rg
  name: 'keyvault${deploymentTimestamp}'
  params: {
    azureKeyVaultName: azureKeyVaultName
    securityGroupName: securityGroupName
    securityGroupid: securityGroupid
    sqlAdministratorPassword: sqlAdministratorPassword
  }
  dependsOn: [
    DeployLogAnalytics
  ]
}

module DeployADLS './modules/adls.bicep' = {
  scope: rg
  name: 'adls${deploymentTimestamp}'
  params: {
    azureDataLakeStoreAccountName: azureDataLakeStoreAccountName
    securityGroupName: securityGroupName
    envName: envName
    securityGroupid: securityGroupid
  }
  dependsOn: [DeployLogAnalytics]
}

module DeployEventHub './modules/eventhub.bicep' = if (optionalDeployEventHub) {
  scope: rg
  name: 'eventhub${deploymentTimestamp}'
  params: {
    eventHubName: eventHubName
    eventHubNameSpaceName: eventHubNameSpaceName
  }
  dependsOn: [DeployLogAnalytics]
}

module DeploySQLServer './modules/sqlserver.bicep' = if (optionalDeploySqlServer) {
  scope: rg
  name: 'sqlserver${deploymentTimestamp}'
  params: {
    azureSqlServerName: azureSqlServerName
    sqlAdministratorLogin: sqlAdministratorLogin
    sqlAdministratorPassword: sqlAdministratorPassword
    securityGroupName: securityGroupName
    securityGroupid: securityGroupid
  }
  dependsOn: [DeployLogAnalytics]
}

module DeploySQLDB './modules/sqldb.bicep' = if (optionalDeploySqlDb) {
  scope: rg
  name: 'sqldb${deploymentTimestamp}'
  params: {
    azureSqlServerName: azureSqlServerName
    azureSqlDatabaseName: azureSqlDatabaseName
  }
  dependsOn: [
    DeploySQLServer
    DeployLogAnalytics
  ]
}

module DeployADBWS './modules/adbws.bicep' = if (optionalDeployADBWorkspace) {
  scope: rg
  name: 'adbws${deploymentTimestamp}'
  params: {
    azureDatabricksName: databricksWorkspaceName
    azureDatabricksManagedName: azureDatabricksManagedName
    databricksNPIP: databricksNPIP
  }
  dependsOn: [DeployLogAnalytics]
}

module DeployADF './modules/adf.bicep' = if (optionalDeployADF) {
  scope: rg
  name: 'adf${deploymentTimestamp}'
  params: {
    azureDataFactoryName: azureDataFactoryName
    azureDataLakeStoreAccountName: azureDataLakeStoreAccountName
    azureKeyVaultName: azureKeyVaultName
    sqlAdministratorLogin: sqlAdministratorLogin
    sqlAdministratorPassword: sqlAdministratorPassword
    databricksWorkspaceName: databricksWorkspaceName
    envName: envName
  }
  dependsOn: [
    DeployKeyVault
    DeploySQLDB
    DeployADLS
    DeployLogAnalytics
  ]
}

module Diagnostics './modules/diagnostics.bicep' = {
  scope: rg
  name: 'diag${deploymentTimestamp}'
  params: {
    logAnalyticsName: logAnalyticsName
    azureDataFactoryName: azureDataFactoryName
    azureDataLakeStoreAccountName: azureDataLakeStoreAccountName
    azureKeyVaultName: azureKeyVaultName
    azureSqlServerName: azureSqlServerName
    azureSqlDatabaseName: azureSqlDatabaseName
    eventHubNameSpaceName: eventHubNameSpaceName
  }
  dependsOn:[
    DeploySQLServer
    DeploySQLDB
    DeployLogAnalytics
    DeployKeyVault
    DeployEventHub
    DeployADLS
    DeployADF
    DeployADBWS
  ]
}
