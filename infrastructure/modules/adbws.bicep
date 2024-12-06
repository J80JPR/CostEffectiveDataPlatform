param location string = resourceGroup().location
@minLength(6)
param azureDatabricksName string
param azureDatabricksManagedName string
param databricksNPIP bool

// Deploy resource
resource databricksWorkspace 'Microsoft.Databricks/workspaces@2024-09-01-preview' =  {
  name: azureDatabricksName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    managedResourceGroupId: subscriptionResourceId('Microsoft.Resources/resourceGroups', azureDatabricksManagedName)
    parameters: {
      enableNoPublicIp: { value: databricksNPIP }
    }
  }
}
