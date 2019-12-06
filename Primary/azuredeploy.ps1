$baseurl = "https://github.com/azuregomez/PaaSDR/Primary"
$templateUrl = $baseurl + "azuredeploy.json"
$paramUrl = $baseurl + "azuredeploy-parameters.json"
#get prefix from parameter file
$param = Get-Content -Raw -Path azuredeploy-parameters.json | ConvertFrom-Json
# using template naming conventions for rg, app and keyvault
$prefix = $param.parameters.resourcenameprefix.value
$app = $prefix + "Web"
$vaultname = $prefix + "-kv"
$rgname = $prefix + "-rg"
$location = "East US"
$rg = get-AzResourcegroup -location $location -name $rgname
if ($null -eq $rg)
{
    new-AzResourcegroup -location $location -name $rgname
}
# deploy AKV, ASP, Web Site, TrafficManager
New-AzResourceGroupDeployment -ResourceGroupName $rgname -TemplateUri $templateUrl -TemplateParameterUri $paramUrl
# Add App to AKV
Write-Information "Adding App MSI to AKV ..."
$principal = Get-AzADServicePrincipal -displayname $app
$objectid = $principal.Id
Set-AzKeyVaultAccessPolicy -vaultname $vaultname -objectid $objectid -permissionsToSecrets get
# Update version of secret in App CnString section
$secretname = "dbcnstr"
$secret = get-azkeyvaultsecret -vaultname $vaultname -name $secretname
$secret.version
$kvref = "@Microsoft.KeyVault(SecretUri=https://" + $vaultname + ".vault.azure.net/secrets/" +  $secretname + "/" + $secret.version + ")"
$newcnstr = (@{Name=$secretname;Type="SQLAzure";ConnectionString=$kvref})
$webapp = get-azwebapp  -resourcegroup $rgname -name $app
$webapp.SiteConfig.ConnectionStrings.Add($newcnstr)
set-azwebapp $webapp
Write-Output "done"
