$uri = "<webhook_uri>"
$param  = @{ 
    armTemplateUri="<arm_template_uri>";
    drResourceGroup="<dr_resource_group>";
    drLocation="West US";
    vaultname="<KV_name>";
	sqlFailoverGroupRG="<failover_group_rg>";
	sqlFailoverGroupName="<failover_grouo_name>";
    sqlFailoverGroupDRServer = "<dr_sql_sever>";
    trafficManagerProfileName = "<tm_profile>";
    trafficManagerRG = "<tm_rg>";
    appServicePlanName = "<new_dr_asp_name>";
    appServicePlanSkuName = "S1";
    appServiceName = "<app_name>";
    repoURL = "https://github.com/azuregomez/PersonDemo";    
}		
$body = ConvertTo-Json -InputObject $param
$response = Invoke-RestMethod -Method Post -Uri $uri -Body $body
$response.JobIds