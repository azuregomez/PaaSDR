# DR Failover WebHook Parameters param
param(
   [Parameter (Mandatory = $true)]
   [object]$WebhookData        
)
if ($nul -ne $WebhookData) {
    $WebhookBody = $WebHookData.RequestBody
    $input = (ConvertFrom-Json -InputObject $WebhookBody)     
    # UnWrap Parameters:   
    # ARM template Uri from Storage Account
    $templateuri = $input.armTemplateUri
    # DR Resource Group and location
    $rgname = $input.drResourceGroup
    $location = $input.drLocation
    # Existing AKV where the cnString is stored
    $vaultname = $input.vaultname
    # SQL DB Failover parameters
    $fogrg = $input.sqlFailoverGroupRG
    $fgname = $input.sqlFailoverGroupName
    $servername = $input.sqlFailoverGroupDRServer
    # Existing Traffic Manager 
    $tmpName = $input.trafficManagerProfileName
    $tmprgName = $input.trafficManagerRG
    # New DR App Service Parameters: ASP, SKU, Web App name and Github Repo URL
    $appServicePlanName = $input.appServicePlanName    
    $appServiceName = $input.appServiceName    
    #login to azure
    $connectionName = "AzureRunAsConnection"
    try{
        "Logging in to Azure..."    
        $connection = Get-AutomationConnection -Name $connectionName
        Connect-AzAccount -ServicePrincipal `
                      -Tenant $connection.TenantId `
                      -ApplicationID $connection.ApplicationId `
                      -CertificateThumbprint $connection.CertificateThumbprint    
    }
    catch {
        if (!$servicePrincipalConnection){
            $ErrorMessage = "Connection $connectionName not found."
            throw $ErrorMessage
        } 
        else{
            Write-Error -Message $_.Exception
            throw $_.Exception
        }
    }
    # This is where the work starts:
    try {
        $rg = get-azresourcegroup -location $location -name $rgname
    }
    catch{
        $rg=$null
    }    
    #Create Azure Resource Group if not already there
    if ($null -eq $rg)
    {
        new-azresourcegroup -location $location -name $rgname
        Write-Output "Resource Group Created ..."
    }
    else {
        Write-Output "Resource Group Already Exists"
    }
    # Preparing ARM template parameter object       
    $azureparams = @{         				
        appServicePlanName = $appServicePlanName        
        appServiceName = $appServiceName
        }
    write-Output "Creating ASP, Web Site and deploying code ..." 
    # deploy arm template 
    New-AzResourceGroupDeployment -ResourceGroupName $rgname -Templateuri $templateuri -TemplateParameterObject $azureparams    
    # done!
    # Add App to AKV
    Write-Output "Adding App MSI to AKV ..."
    $app = get-azwebapp -name $appServiceName    
    $objectid = $app.Identity.PrincipalId
    Set-AzKeyVaultAccessPolicy -vaultname $vaultname -BypassObjectIdValidation -objectid $objectid -permissionsToSecrets get
    # Update version of secret in App CnString section
    $secretname = "dbcnstr"
    $secret = get-azkeyvaultsecret -vaultname $vaultname -name $secretname
    $secret.version
    $kvref = "@Microsoft.KeyVault(SecretUri=https://" + $vaultname + ".vault.azure.net/secrets/" +  $secretname + "/" + $secret.version + ")"
    $newcnstr = (@{Name=$secretname;Type="SQLAzure";ConnectionString=$kvref})
    $webapp = get-azwebapp  -resourcegroup $rgname -name $appServiceName
    $webapp.SiteConfig.ConnectionStrings.Add($newcnstr)
    set-azwebapp $webapp
    # Manual SQLDB Failover
    Write-Output "Executing SQL Failover ..."
    Switch-AzSqlDatabaseFailoverGroup -resourcegroupname $fogrg -servername $servername -FailoverGroupName $fgname
    Get-AzSqlDatabaseFailoverGroup -servername lakeview2 -resourcegroupname $fogrg
    # Update Traffic Mananger
    Write-Output "Updating Traffic Manager ..."
    $tmp = Get-AzTrafficManagerProfile -Name $tmpName -ResourceGroupName $tmprgName
    $epname = $tmp.Endpoints[0].Name
    Disable-AzTrafficManagerEndpoint -name $epname -type "azureEndpoints" -profilename $tmpName -resourcegroupname $tmprgname -force
    $drsite = get-azwebapp -name $appServiceName
    New-AzTrafficManagerEndpoint -EndpointStatus Enabled -Name "DR" -ProfileName $tmpName -ResourceGroupName $tmprgName -Type AzureEndpoints -Priority 2 -TargetResourceId $drsite.Id -Weight 10
    write-Output "Failover Complete"
}
else {
   Write-Error "Failover Runbook to be started only from webhook."
}
