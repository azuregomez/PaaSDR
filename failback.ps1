# TODO: make this script an Azure Automation Runbook
# Failback SQL Server
$rgname = "<resource_group_for _faiover_group>"
$fgname = "<failover_group_name>"
$servername = "<current_dr_sq_server_name>"
Switch-AzureRMSqlDatabaseFailoverGroup -resourcegroupname $rgname -servername $servername -FailoverGroupName $fgname
Get-AzureRMSqlDatabaseFailoverGroup -servername $servername -resourcegroupname $rgname
# Update Traffic Mananger
Write-Output "Failback Traffic Manager ..."
$tmpName = "<traffic_manager_profile_name>"
$tmprgname = "<traffic_manager_resource_group_name>"
$epname = "<endpoint_name_to_be_enabled>"
Enable-AzureRmTrafficManagerEndpoint -name $epname -type "azureEndpoints" -profilename $tmpName -resourcegroupname $tmprgname 
$drname = "<dr_endpoint_name_to_be_deleted>"
Remove-AzureRmTrafficManagerEndpoint -Name $drname -ProfileName $tmpName -ResourceGroupName $tmprgName -Type AzureEndpoints -force
write-Output "Failback Complete"