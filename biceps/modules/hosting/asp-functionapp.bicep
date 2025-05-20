param location string
param tags object = {}
param appServicePlanFxName string

module asp 'br/public:avm/res/web/serverfarm:0.4.1' = {
  name: 'Deploy-${appServicePlanFxName}'
  params: {
    name: appServicePlanFxName
    location: location
    tags: tags
    kind: 'app'
    skuName: 'S1'
    zoneRedundant: false
    elasticScaleEnabled: false
    skuCapacity: 1
  }
}

output AppServicePlanId string = asp.outputs.resourceId
