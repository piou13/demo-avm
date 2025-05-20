param tags object = {}
param vNetId string

module privateDnsZoneBlob 'br/public:avm/res/network/private-dns-zone:0.7.1' = {
  name: 'Deploy-PrivateDnsZone-blob'
  params: {
    name: 'privatelink.blob.${environment().suffixes.storage}'
    tags: tags
    virtualNetworkLinks: [
      {
        name: 'privateDnsZoneBlobLink'
        virtualNetworkResourceId: vNetId
      }
    ]
  }
}

module privateDnsZoneFile 'br/public:avm/res/network/private-dns-zone:0.7.1' = {
  name: 'Deploy-PrivateDnsZone-file'
  params: {
    name: 'privatelink.file.${environment().suffixes.storage}'
    tags: tags
    virtualNetworkLinks: [
      {
        name: 'privateDnsZoneFileLink'
        virtualNetworkResourceId: vNetId
      }
    ]
  }
}

module privateDnsZonesTable 'br/public:avm/res/network/private-dns-zone:0.7.1' = {
  name: 'Deploy-PrivateDnsZone-table'
  params: {
    name: 'privatelink.table.${environment().suffixes.storage}'
    tags: tags
    virtualNetworkLinks: [
      {
        name: 'privatelink.table.${environment().suffixes.storage}'
        virtualNetworkResourceId: vNetId
      }
    ]
  }
}

module privateDnsZonesQueue 'br/public:avm/res/network/private-dns-zone:0.7.1' = {
  name: 'Deploy-PrivateDnsZone-queue'
  params: {
    name: 'privatelink.queue.${environment().suffixes.storage}'
    tags: tags
    virtualNetworkLinks: [
      {
        name: 'privatelink.queue.${environment().suffixes.storage}'
        virtualNetworkResourceId: vNetId
      }
    ]
  }
} 

module privateDnsZoneSites 'br/public:avm/res/network/private-dns-zone:0.7.1' = {
  name: 'Deploy-PrivateDnsZone-sites'
  params: {
    name: 'privatelink.azurewebsites.net'
    tags: tags
    virtualNetworkLinks: [
      {
        name: 'privateDnsZoneSitesLink'
        virtualNetworkResourceId: vNetId
      }
    ]
  }
}

module privateDnsZoneKeyvault 'br/public:avm/res/network/private-dns-zone:0.7.1' = {
  name: 'Deploy-PrivateDnsZone-keyvault'
  params: {
    name: 'privatelink.vaultcore.azure.net'
    tags: tags
    virtualNetworkLinks: [
      {
        name: 'privateDnsZoneKeyvaultLink'
        virtualNetworkResourceId: vNetId
      }
    ]
  }
}

output privateDnsZoneBlobId string = privateDnsZoneBlob.outputs.resourceId
output privateDnsZoneFileId string = privateDnsZoneFile.outputs.resourceId
output privateDnsZoneTableId string = privateDnsZonesTable.outputs.resourceId
output privateDnsZoneQueueId string = privateDnsZonesQueue.outputs.resourceId
output privateDnsZoneSitesId string = privateDnsZoneSites.outputs.resourceId
output privateDnsZoneKeyvaultId string = privateDnsZoneKeyvault.outputs.resourceId
