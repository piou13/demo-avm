param location string
param tags object = {}
param userAssignedIdentityName string

module userAssignedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.1' = {
  name: 'Deploy-${userAssignedIdentityName}'
  params: {
    name: userAssignedIdentityName
    location: location
    tags: tags
  }
}

output resourceId string = userAssignedIdentity.outputs.resourceId
output principalId string = userAssignedIdentity.outputs.principalId
output clientId string = userAssignedIdentity.outputs.clientId
