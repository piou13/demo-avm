param location string
param tags object = {}
param functionAppName string
param peResourceGroupId string
param peSubnetId string
param fxSubnetId string
param privateDnsZonesSiteid string
param appServicePlanId string
param storageAccountId string
param userAssignedIdentityResourceId string
param authSettingV2Configuration object = {}

var appSettings = {
  FUNCTIONS_EXTENSION_VERSION: '~4'
  FUNCTIONS_WORKER_RUNTIME: 'dotnet-isolated'
  WEBSITE_USE_PLACEHOLDER_DOTNETISOLATED: '1'
  WEBSITE_RUN_FROM_PACKAGE: '0'
}

var appSettingsKeyValuePairs = empty(authSettingV2Configuration)
  ? appSettings
  : union(appSettings, { WEBSITE_AUTH_AAD_ALLOWED_TENANTS: tenant().tenantId })

module functionAppClient 'br/public:avm/res/web/site:0.15.1' = {
  name: 'Deploy-${functionAppName}'
  params: {
    name: functionAppName
    location: location
    tags: tags
    kind: 'functionapp'
    serverFarmResourceId: appServicePlanId
    managedIdentities: {
      systemAssigned: true
      userAssignedResourceIds: [
        userAssignedIdentityResourceId
      ]
    }
    publicNetworkAccess: 'Disabled'
    httpsOnly: true
    vnetRouteAllEnabled: true
    vnetContentShareEnabled: true
    storageAccountResourceId: storageAccountId
    storageAccountUseIdentityAuthentication: true
    appSettingsKeyValuePairs: appSettingsKeyValuePairs
    authSettingV2Configuration: authSettingV2Configuration
    virtualNetworkSubnetId: fxSubnetId
    privateEndpoints: [
      {
        name: 'pe-${functionAppName}'
        service: 'sites'
        subnetResourceId: peSubnetId
        customNetworkInterfaceName: 'nic-${functionAppName}'
        privateLinkServiceConnectionName: 'link-${functionAppName}'
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
  name: 'rbac-storage-${functionAppName}'
  params: {
    appPrincipalId: functionAppClient.outputs.systemAssignedMIPrincipalId!
    storageAccountResourceId: storageAccountId
  }
}

output resourceId string = functionAppClient.outputs.resourceId
output url string = functionAppClient.outputs.defaultHostname
output principalId string = functionAppClient.outputs.?systemAssignedMIPrincipalId!
