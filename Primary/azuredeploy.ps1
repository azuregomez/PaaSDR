#Deploy Primary solution and enroll in AKV
$rgname = "<resource_group_name>"
$location = "<primary_location>"
$baseurl = "https://github.com/azuregomez/PaaSDR/Primary"
$rg = get-azurermresourcegroup -location $location -name $rgname
if ($null -eq $rg)
{
    new-azurermresourcegroup -location $location -name $rgname
}
$templateUrl = $baseurl + "azuredeploy.json"
$paramUrl = $baseurl + "azuredeploy-parameters.json"
# deploy AKV, ASP, Web Site, TrafficManager
New-AzureRmResourceGroupDeployment -ResourceGroupName $rgname -TemplateUri $templateUrl -TemplateParameterUri $paramUrl
# Add App to AKV
Write-Information "Adding App MSI to AKV ..."
$param = Get-Content -Raw -Path azuredeploy-parameters.json | ConvertFrom-Json
$app = $param.parameters.appServiceName.value
$vaultname = $param.parameters.keyVaultName.value
$principal = Get-AzureRmADServicePrincipal -displayname $app
$objectid = $principal.Id
Set-AzureRmKeyVaultAccessPolicy -vaultname $vaultname -objectid $objectid -permissionsToSecrets get
Write-Output "done"
