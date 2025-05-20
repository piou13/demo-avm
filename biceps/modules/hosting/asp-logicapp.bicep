param location string
param tags object = {}
param appServicePlanLaName string

module asp 'br/public:avm/res/web/serverfarm:0.4.1' = {
  name: 'Deploy-${appServicePlanLaName}'
  params: {
    name: appServicePlanLaName
    location: location
    tags: tags
    kind: 'elastic'
    skuName: 'WS1'
    zoneRedundant: false
    perSiteScaling: false
    elasticScaleEnabled: true
    maximumElasticWorkerCount: 1
    skuCapacity: 1
  }
}

output AppServicePlanId string = asp.outputs.resourceId
