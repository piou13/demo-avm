param location string
param tags object = {}
param storageAccountName string
param shares array = []
param peResourceGroupId string
param peSubnetId string
param keyvaultResourceId string = ''
param privateDnsZonesBlobId string
param privateDnsZonesFileId string
param privateDnsZonesTableId string
param privateDnsZonesQueueId string

module storageAccount 'br/public:avm/res/storage/storage-account:0.19.0' = {
  name: 'Deploy-${storageAccountName}'
  params: {
    name: storageAccountName
    location: location
    tags: tags
    skuName: 'Standard_LRS'
    allowBlobPublicAccess: false
    accessTier: 'Hot'
    kind: 'StorageV2'
    publicNetworkAccess: 'Disabled'
    allowSharedKeyAccess: true
    secretsExportConfiguration: keyvaultResourceId == '' ? null : {
      keyVaultResourceId: keyvaultResourceId
      accessKey1Name: '${storageAccountName}-accessKey1Name'
      accessKey2Name: '${storageAccountName}-accessKey2Name'
      connectionString1Name: '${storageAccountName}-connectionString1Name'
      connectionString2Name: '${storageAccountName}-connectionString2Name'
    }
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
    blobServices: {
      containerDeleteRetentionPolicyEnabled: false
    }
    fileServices: {
      shareDeleteRetentionPolicy: {
        days: 7
        enabled: false
      }
      shares: [
        for share in shares: {
          name: share
        }
      ]
    }
    privateEndpoints: [
      {
        name: 'pe-blob-${storageAccountName}'
        service: 'blob'
        subnetResourceId: peSubnetId
        customNetworkInterfaceName: 'nic-blob-${storageAccountName}'
        privateLinkServiceConnectionName: 'link-blob-${storageAccountName}'
        resourceGroupResourceId: peResourceGroupId
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: privateDnsZonesBlobId
            }
          ]
        }
      }
      {
        name: 'pe-file-${storageAccountName}'
        service: 'file'
        subnetResourceId: peSubnetId
        customNetworkInterfaceName: 'nic-file-${storageAccountName}'
        privateLinkServiceConnectionName: 'link-file-${storageAccountName}'
        resourceGroupResourceId: peResourceGroupId
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: privateDnsZonesFileId
            }
          ]
        }
      }
      {
        name: 'pe-table-${storageAccountName}'
        service: 'table'
        subnetResourceId: peSubnetId
        customNetworkInterfaceName: 'nic-table-${storageAccountName}'
        privateLinkServiceConnectionName: 'link-table-${storageAccountName}'
        resourceGroupResourceId: peResourceGroupId
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: privateDnsZonesTableId
            }
          ]
        }
      }
      {
        name: 'pe-queue-${storageAccountName}'
        service: 'queue'
        subnetResourceId: peSubnetId
        customNetworkInterfaceName: 'nic-queue-${storageAccountName}'
        privateLinkServiceConnectionName: 'link-queue-${storageAccountName}'
        resourceGroupResourceId: peResourceGroupId
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: privateDnsZonesQueueId
            }
          ]
        }
      }
    ]
  }
}

output name string = storageAccount.outputs.name
output resourceId string = storageAccount.outputs.resourceId
