param appPrincipalId string
param storageAccountResourceId string

var storageRoleIds = [
  'b7e6dc6d-f1e8-4753-8033-0f276bb0955b' // Storage Blob Data Owner
  '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3' // Storage Table Data Contributor
]

module rbac 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = [for roleId in storageRoleIds: {
  name: uniqueString('${appPrincipalId}-${storageAccountResourceId}-${roleId}')
  params: {
    resourceId: storageAccountResourceId
    principalId: appPrincipalId
    roleDefinitionId: roleId
    principalType: 'ServicePrincipal'
  }
}]
