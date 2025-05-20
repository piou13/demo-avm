using '../main.bicep'

var solutionName = '<YOUR SOLUTION NAME (only lowercase letters and numbers)>'

param location  = 'canadacentral'
param tags = { Category: 'DEMO-AVM' }
param resourceGroupNetworkName = 'rg-${solutionName}-network'
param resourceGroupServicesName = 'rg-${solutionName}-services'
param appServicePlanFxName = 'asp-fx-${solutionName}'
param appServicePlanLaName = 'asp-la-${solutionName}'
param vNetName = 'vnet-${solutionName}'
param storageAccountFxName = take('safx${solutionName}${uniqueString(solutionName)}', 24)
param storageAccountLaName = take('sala${solutionName}${uniqueString(solutionName)}', 24)
param functionAppName = 'fx-${solutionName}-${uniqueString(solutionName)}'
param logicAppName = 'la-${solutionName}-${uniqueString(solutionName)}'
param keyvaultName = take('kv${solutionName}${uniqueString(solutionName)}', 24)
param userAssignedIdentityName =  'uai-${solutionName}'
