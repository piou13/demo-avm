Set-Location $PSScriptRoot

Connect-AzAccount -TenantId "<YOUR TENANT ID>" -Subscription "<YOUR SUBSCRIPTION ID>"

## Deploy Infra
<##>
Write-Host "Deploying the infra..." -ForegroundColor Magenta
$deployment = New-AzSubscriptionDeployment -Name "DEMO_AVM" `
    -Location "canadacentral" `
    -TemplateFile biceps\main.bicep `
    -TemplateParameterFile biceps\params\main.bicepparam


## Setup local installation folders
$tempInstallFolder = "$([System.IO.Path]::GetTempPath())$(New-Guid)"
New-Item -ItemType Directory -Path $tempInstallFolder -Force | Out-Null
$tempWfPath = (New-Item -ItemType Directory -Path $tempInstallFolder\wf -Force).FullName
$tempFxPath = (New-Item -ItemType Directory -Path $tempInstallFolder\fx -Force).FullName

## Deploy the Function App and the Logic App Standard Workflow for the demo
$rgName = $deployment.Outputs.functionAppResourceGroupName.Value
$laName = $deployment.Outputs.logicAppName.Value
$fxName = $deployment.Outputs.functionAppName.Value
$fxEndpoint = "https://$fxName.azurewebsites.net/api/CallFunction"
$uaiResourceId = $deployment.Outputs.userAssignedManagedIdentityId.Value

<#
NOTE:
For the sake of this demo and because deploying behind private endpoints can be cumbersome,
we temporarly disable isolation from public networks to easily deploy Function App function.
We re-enable it after the deployment.
This is, of course, not recommended except for testing purposes.
#>
Write-Host "Temporarly disable network isolation..." -ForegroundColor Magenta
$fx = Get-AzResource -Name $fxName -ResourceGroupName $rgName -ResourceType Microsoft.Web/sites
$fx.Properties.publicNetworkAccess = "Enabled"
$fx | Set-AzResource -Force | Out-Null

# Logic App Standard
Write-Host "Deploy the LogicApp workflow..." -ForegroundColor Magenta
Get-ChildItem -Path .\apps\workflow | Copy-Item -Destination $tempWfPath -Recurse -Force
$parameters = Get-Content -Path $tempWfPath\parameters.json -Raw
$parameters = $parameters -replace "#__userAssignedIdentityId__#", $uaiResourceId -replace "#__functionAppEndpoint__#", $fxEndpoint
$parameters | Set-Content -Path $tempWfPath\parameters.json -Force

Compress-Archive -Path $tempWfPath\* -DestinationPath $tempWfPath\workflow.zip -Force
Publish-AzWebApp -Name $laName -ResourceGroupName $rgName -ArchivePath $tempWfPath\workflow.zip -Force | Out-Null

# Function App
Write-Host "Deploy the FunctionApp function..." -ForegroundColor Magenta
dotnet build apps\function\fx.sln --configuration Release
dotnet publish apps\function\fx.csproj --configuration Release --output $tempFxPath
Compress-Archive -Path $tempFxPath\* -DestinationPath $tempFxPath\function.zip -Force
Publish-AzWebApp -Name $fxName -ResourceGroupName $rgName -ArchivePath $tempFxPath\function.zip -Force | Out-Null

# Restore isolation from public networks
Write-Host "Restore network isolation..." -ForegroundColor Magenta
$fx.Properties.publicNetworkAccess = "Disabled"
$fx | Set-AzResource -Force | Out-Null

# Clean-up app packages
Write-Host "Clean-up..." -ForegroundColor Magenta
Remove-Item -Path $tempInstallFolder -Recurse -Force