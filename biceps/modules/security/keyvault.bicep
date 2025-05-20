param location string
param keyvaultName string
param peResourceGroupId string
param peSubnetId string
param privateDnsZoneId string
param roleAssignments array = []

module keyvault 'br/public:avm/res/key-vault/vault:0.12.1' = {
  name: 'Deploy-${keyvaultName}'
  params: {
    name: keyvaultName
    location: location
    sku: 'standard'
    enableRbacAuthorization: true
    enableSoftDelete: false
    publicNetworkAccess: 'Disabled'
    privateEndpoints: [
      {
        name: 'pe-${keyvaultName}'
        service: 'vault'
        subnetResourceId: peSubnetId
        customNetworkInterfaceName: 'nic-${keyvaultName}'
        privateLinkServiceConnectionName: 'link-${keyvaultName}'
        resourceGroupResourceId: peResourceGroupId
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: privateDnsZoneId
            }
          ]
        }
      }
    ]
    roleAssignments: roleAssignments
  }
}

output name string = keyvault.outputs.name
output resourceId string = keyvault.outputs.resourceId
