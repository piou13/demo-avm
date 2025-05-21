targetScope = 'subscription'

param location string
param tags object = {}
param resourceGroupNetworkName string
param resourceGroupServicesName string
param vNetName string
param storageAccountFxName string
param storageAccountLaName string
param appServicePlanFxName string
param appServicePlanLaName string
param functionAppName string
param logicAppName string
param keyvaultName string
param userAssignedIdentityName string

// Deploy Resources Groups

module resourceGroupNetwork 'br/public:avm/res/resources/resource-group:0.4.1' = {
  name: resourceGroupNetworkName
  params: {
    name: resourceGroupNetworkName
    location: location
    tags: tags
  }
}

module resourceGroupServices 'br/public:avm/res/resources/resource-group:0.4.1' = {
  name: resourceGroupServicesName
  params: {
    name: resourceGroupServicesName
    location: location
    tags: tags
  }
}

// Deploy Network Resources

module network 'modules/network/vnet.bicep' = {
  scope: resourceGroup(resourceGroupNetworkName)
  name: 'Network'
  params: {
    location: location
    tags: tags
    vNetName: vNetName
  }
  dependsOn: [
    resourceGroupNetwork
  ]
}

// Deploy DNS Settings

module privateDnsZones 'modules/network/dns.bicep' = {
  scope: resourceGroup(resourceGroupNetworkName)
  name: 'PrivateDnsZones'
  params: {
    vNetId: network.outputs.vnetResourceId
  }
}

// Deploy User Assigned Managed Identity to configure connection to Keyvault from AppSettings when required and use it for EasyAuth

module userAssignedIdentity 'modules/identity/user-assigned-identity.bicep' = {
  scope: resourceGroup(resourceGroupServices.name)
  name: 'UserAssignedIdentity'
  params: {
    location: location
    tags: tags
    userAssignedIdentityName: userAssignedIdentityName
  }
}

// Deploy KeyVault

module keyvault 'modules/security/keyvault.bicep' = {
  scope: resourceGroup(resourceGroupServices.name)
  name: 'KeyVault'
  params: {
    location: location
    keyvaultName: keyvaultName
    peSubnetId: network.outputs.subnetPeId
    privateDnsZoneId: privateDnsZones.outputs.privateDnsZoneKeyvaultId
    peResourceGroupId: resourceGroupNetwork.outputs.resourceId
    roleAssignments: [
      {
        principalId: userAssignedIdentity.outputs.principalId
        roleDefinitionIdOrName: 'Key Vault Secrets User'
        principalType: 'ServicePrincipal'
      }
    ]
  }
}

// Deploy Storage Account for Function App and Logic App

module storageAccountFx 'modules/storage/storage-account.bicep' = {
  scope: resourceGroup(resourceGroupServices.name)
  name: 'StorageAccountFx'
  params: {
    location: location
    tags: tags
    storageAccountName: storageAccountFxName
    peResourceGroupId: resourceGroupNetwork.outputs.resourceId
    peSubnetId: network.outputs.subnetPeId
    keyvaultResourceId: keyvault.outputs.resourceId
    privateDnsZonesBlobId: privateDnsZones.outputs.privateDnsZoneBlobId
    privateDnsZonesFileId: privateDnsZones.outputs.privateDnsZoneFileId
    privateDnsZonesTableId: privateDnsZones.outputs.privateDnsZoneTableId
    privateDnsZonesQueueId: privateDnsZones.outputs.privateDnsZoneQueueId
  }
}

module storageAccountLa 'modules/storage/storage-account.bicep' = {
  scope: resourceGroup(resourceGroupServices.name)
  name: 'StorageAccountLa'
  params: {
    location: location
    tags: tags
    storageAccountName: storageAccountLaName
    peResourceGroupId: resourceGroupNetwork.outputs.resourceId
    peSubnetId: network.outputs.subnetPeId
    keyvaultResourceId: keyvault.outputs.resourceId
    privateDnsZonesBlobId: privateDnsZones.outputs.privateDnsZoneBlobId
    privateDnsZonesFileId: privateDnsZones.outputs.privateDnsZoneFileId
    privateDnsZonesTableId: privateDnsZones.outputs.privateDnsZoneTableId
    privateDnsZonesQueueId: privateDnsZones.outputs.privateDnsZoneQueueId
    shares: [
      logicAppName
    ]
  }
}

// Deploy App Service Plans for Function App and Logic App

module appServicePlanFx 'modules/hosting/asp-functionapp.bicep' = {
  scope: resourceGroup(resourceGroupServices.name)
  name: 'AppServicePlanFx'
  params: {
    location: location
    appServicePlanFxName: appServicePlanFxName
  }
}

module appServicePlanLa 'modules/hosting/asp-logicapp.bicep' = {
  scope: resourceGroup(resourceGroupServices.name)
  name: 'AppServicePlanLa'
  params: {
    location: location
    appServicePlanLaName: appServicePlanLaName
  }
}

// Deploy Logic App Standard

module logicApp 'modules/web/logic-app-standard.bicep' = {
  scope: resourceGroup(resourceGroupServices.name)
  name: 'LogicAppStandard'
  params: {
    location: location
    tags: tags
    logicAppName: logicAppName
    appServicePlanId: appServicePlanLa.outputs.AppServicePlanId
    peResourceGroupId: resourceGroupNetwork.outputs.resourceId
    laSubnetId: network.outputs.subnetLaId
    peSubnetId: network.outputs.subnetPeId
    privateDnsZonesSiteid: privateDnsZones.outputs.privateDnsZoneSitesId
    storageAccountLaName: storageAccountLa.outputs.name
    storageAccountLaResourceId: storageAccountLa.outputs.resourceId
    KeyVaultName: keyvault.outputs.name
    userAssignedIdentityResourceId: userAssignedIdentity.outputs.resourceId
    authSettingV2Configuration: {
      globalValidation: {
        requireAuthentication: true
        unauthenticatedClientAction: 'Return401'
      }
      login: {
        tokenStore: {
          enabled: true
        }
      }
      identityProviders: {
        azureActiveDirectory: {
          enabled: true
          registration: {
            clientId: 'FunctionAppAuthSettings'
            openIdIssuer: 'https://sts.windows.net/${tenant().tenantId}/v2.0'
          }
          validation: {
            allowedAudiences: environment().authentication.audiences
          }
        }
      }
    }
  }
}


// Deploy the Function App and set the EasyAuth config for the Logic Apps

module functionApp 'modules/web/function-app.bicep' = {
  scope: resourceGroup(resourceGroupServices.name)
  name: 'FunctionApp'
  params: {
    location: location
    tags: tags
    functionAppName: functionAppName
    appServicePlanId: appServicePlanFx.outputs.AppServicePlanId
    peResourceGroupId: resourceGroupNetwork.outputs.resourceId
    fxSubnetId: network.outputs.subnetFxId
    peSubnetId: network.outputs.subnetPeId
    privateDnsZonesSiteid: privateDnsZones.outputs.privateDnsZoneSitesId
    storageAccountId: storageAccountFx.outputs.resourceId
    userAssignedIdentityResourceId: userAssignedIdentity.outputs.resourceId
    authSettingV2Configuration: {
      globalValidation: {
        requireAuthentication: true
        unauthenticatedClientAction: 'Return401'
      }
      login: {
        tokenStore: {
          enabled: true
        }
      }
      identityProviders: {
        azureActiveDirectory: {
          enabled: true
          registration: {
            clientId: 'LogicAppAuthSettings'
            openIdIssuer: 'https://sts.windows.net/${tenant().tenantId}/v2.0'
          }
          validation: {
            allowedAudiences: environment().authentication.audiences
            defaultAuthorizationPolicy: {
              allowedApplications: [
                userAssignedIdentity.outputs.clientId
              ]
              allowedPrincipals: {
                identities: [
                  userAssignedIdentity.outputs.principalId
                ]
              }
            }
          }
        }
      }
    }
  }
}


// Outputs used to pass values used by the samples
output functionAppResourceGroupName string = resourceGroupServicesName
output functionAppName string = functionAppName
output logicAppName string = logicAppName
output userAssignedManagedIdentityId string = userAssignedIdentity.outputs.resourceId
