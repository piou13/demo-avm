param location string
param tags object = {}
param logicAppName string
param peResourceGroupId string
param peSubnetId string
param laSubnetId string
param privateDnsZonesSiteid string
param appServicePlanId string
param storageAccountLaName string
param storageAccountLaResourceId string
param KeyVaultName string
param userAssignedIdentityResourceId string
param authSettingV2Configuration object = {}

var appSettings = {
  FUNCTIONS_EXTENSION_VERSION: '~4'
  FUNCTIONS_WORKER_RUNTIME: 'dotnet'
  APP_KIND: 'workflowApp'
  AzureFunctionsJobHost__extensionBundle__id: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
  AzureFunctionsJobHost__extensionBundle__version: '[1.*, 2.0.0)'
  WEBSITE_NODE_DEFAULT_VERSION: '~20'
  WEBSITE_CONTENTSHARE: logicAppName
  WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: '@Microsoft.KeyVault(VaultName=${KeyVaultName};SecretName=${storageAccountLaName}-connectionString1Name)'
  AzureWebJobsStorage: '@Microsoft.KeyVault(VaultName=${KeyVaultName};SecretName=${storageAccountLaName}-connectionString1Name)'
  WEBSITE_RUN_FROM_PACKAGE: '0'
}

var appSettingsKeyValuePairs = empty(authSettingV2Configuration)
  ? appSettings
  : union(appSettings, { WEBSITE_AUTH_AAD_ALLOWED_TENANTS: tenant().tenantId })

module logicApp 'br/public:avm/res/web/site:0.15.1' = {
  name: 'Deploy-${logicAppName}'
  params: {
    name: logicAppName
    location: location
    tags: tags
    kind: 'functionapp,workflowapp'
    serverFarmResourceId: appServicePlanId
    managedIdentities: {
      systemAssigned: true
      userAssignedResourceIds: [
        userAssignedIdentityResourceId
      ]
    }
    publicNetworkAccess: 'Enabled'
    httpsOnly: true
    vnetRouteAllEnabled: true
    vnetContentShareEnabled: true
    storageAccountResourceId: storageAccountLaResourceId
    storageAccountUseIdentityAuthentication: true
    keyVaultAccessIdentityResourceId: userAssignedIdentityResourceId
    siteConfig: {
      functionsRuntimeScaleMonitoringEnabled: false
    }
    appSettingsKeyValuePairs: appSettingsKeyValuePairs
    authSettingV2Configuration: authSettingV2Configuration
    virtualNetworkSubnetId: laSubnetId
    privateEndpoints: [
      {
        name: 'pe-${logicAppName}'
        service: 'sites'
        subnetResourceId: peSubnetId
        customNetworkInterfaceName: 'nic-${logicAppName}'
        privateLinkServiceConnectionName: 'link-${logicAppName}'
        resourceGroupResourceId: peResourceGroupId
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: privateDnsZonesSiteid
            }
          ]
        }
      }
    ]
    
  }
}

// Deploy RBAC for the backend storage account

module rbac '../security/rbac-storage.bicep' = {
  name: 'rbac-storage-${logicAppName}'
  params: {
    appPrincipalId: logicApp.outputs.systemAssignedMIPrincipalId!
    storageAccountResourceId: storageAccountLaResourceId
  }
}

output resourceId string = logicApp.outputs.resourceId
output url string = 'https://${logicApp.outputs.defaultHostname}'
output principalId string = logicApp.outputs.?systemAssignedMIPrincipalId!
