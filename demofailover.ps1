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
    $appServicePlanSkuName = $input.appServicePlanSkuName
    $appServiceName = $input.appServiceName
    $repoURL = $input.repoURL
    #login to azure
    $connectionName = "AzureRunAsConnection"
    try
    {
        # Get the connection "AzureRunAsConnection "
        $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         
        "Logging in to Azure..."
        Add-AzureRmAccount `
            -ServicePrincipal `
            -TenantId $servicePrincipalConnection.TenantId `
            -ApplicationId $servicePrincipalConnection.ApplicationId `
            -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
    }
    catch {
        if (!$servicePrincipalConnection)
        {
            $ErrorMessage = "Connection $connectionName not found."
            throw $ErrorMessage
        } else{
            Write-Error -Message $_.Exception
            throw $_.Exception
        }
    }
    # This is where the work starts:
    $rg = get-azurermresourcegroup -location $location -name $rgname
    #Create Azure Resource Group if not already there
    if ($null -eq $rg)
    {
        new-azurermresourcegroup -location $location -name $rgname
        Write-Output "Resource Group Created ..."
    }
    else {
        Write-Output "Resource Group Already Exists"
    }
    # Prepering ARM template parameter object       
    $azureparams = @{         				
        appServicePlanName = $appServicePlanName
        appServicePlanSkuName = $appServicePlanSkuName
        appServiceName = $appServiceName
        repoURL = $repoURL
        repoBranch = "master"
        }
    write-Output "Creating ASP, Web Site and deploying code ..." 
    # deploy arm template 
    New-AzureRmResourceGroupDeployment -ResourceGroupName $rgname -Templateuri $templateuri -TemplateParameterObject $azureparams    
    # done!$tmpN
    # Add App to AKV
    Write-Output "Adding App MSI to AKV ..."
    $app = get-azurermwebapp -name $appServiceName    
    $objectid = $app.Identity.PrincipalId
    Set-AzureRmKeyVaultAccessPolicy -vaultname $vaultname -BypassObjectIdValidation -objectid $objectid -permissionsToSecrets get
    # Manual SQLDB Failover
    Write-Output "Executing SQL Failover ..."
    Switch-AzureRMSqlDatabaseFailoverGroup -resourcegroupname $fogrg -servername $servername -FailoverGroupName $fgname
    Get-AzureRMSqlDatabaseFailoverGroup -servername lakeview2 -resourcegroupname $fogrg
    # Update Traffic Mananger
    Write-Output "Updating Traffic Manager ..."
    $tmp = Get-AzureRmTrafficManagerProfile -Name $tmpName -ResourceGroupName $tmprgName
    $epname = $tmp.Endpoints[0].Name
    Disable-AzureRmTrafficManagerEndpoint -name $epname -type "azureEndpoints" -profilename $tmpName -resourcegroupname $tmprgname -force
    $drsite = get-azurermwebapp -name $appServiceName
    New-AzureRmTrafficManagerEndpoint -EndpointStatus Enabled -Name "DR" -ProfileName $tmpName -ResourceGroupName $tmprgName -Type AzureEndpoints -Priority 2 -TargetResourceId $drsite.Id -Weight 10
    write-Output "Failover Complete"
}
else {
   Write-Error "Failover Runbook to be started only from webhook."
}
