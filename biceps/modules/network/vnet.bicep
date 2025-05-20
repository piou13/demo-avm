param location string
param tags object = {}
param vNetName string

var subnetFxName = '${vNetName}-snet-fx'
var subnetLaName = '${vNetName}-snet-la'
var subnetPeName = '${vNetName}-snet-pe'

module vnet 'br/public:avm/res/network/virtual-network:0.6.1' = {
  name: 'Deploy-v${vNetName}'
  params: {
    name: vNetName
    location: location
    tags: tags
    addressPrefixes: [
      '10.0.0.0/16'
    ]
    subnets: [
      {
        name: subnetPeName
        addressPrefixes: [
          '10.0.0.0/27'
        ]
        privateEndpointNetworkPolicies: 'Disabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
      }
      {
        name: subnetFxName
        addressPrefixes: [
          '10.0.0.32/29'
        ]
        delegation: 'Microsoft.Web/serverFarms'
        serviceEndpoints: [
          'Microsoft.Storage'
        ]
        privateEndpointNetworkPolicies: 'Enabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
      }
      {
        name: subnetLaName
        addressPrefixes: [
          '10.0.0.40/29'
        ]
        delegation: 'Microsoft.Web/serverFarms'
        serviceEndpoints: [
          'Microsoft.Storage'
        ]
        privateEndpointNetworkPolicies: 'Enabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
      }
    ]
  }
}

output vnetName string = vnet.outputs.name
output vnetResourceId string = vnet.outputs.resourceId
output subnetPeName string = vnet.outputs.subnetNames[indexOf(vnet.outputs.subnetNames, subnetPeName)]
output subnetFxName string = vnet.outputs.subnetNames[indexOf(vnet.outputs.subnetNames, subnetFxName)]
output subnetLaName string = vnet.outputs.subnetNames[indexOf(vnet.outputs.subnetNames, subnetLaName)]
output subnetPeId string = vnet.outputs.subnetResourceIds[indexOf(vnet.outputs.subnetNames, subnetPeName)]
output subnetFxId string = vnet.outputs.subnetResourceIds[indexOf(vnet.outputs.subnetNames, subnetFxName)]
output subnetLaId string = vnet.outputs.subnetResourceIds[indexOf(vnet.outputs.subnetNames, subnetLaName)]
