# TODO: make this script an Azure Automation Runbook
# Failback SQL Server
$rgname = "<resource_group_for_failover_group>"
$fgname = "<failover_group_name>"
$servername = "<desired_primary_sql_server_name>"
Switch-AzSqlDatabaseFailoverGroup -resourcegroupname $rgname -servername $servername -FailoverGroupName $fgname
Get-AzSqlDatabaseFailoverGroup -servername $servername -resourcegroupname $rgname
# Update Traffic Mananger
Write-Output "Failback Traffic Manager ..."
$tmpName = "<traffic_manager_profile_name>"
$tmprgname = "<traffic_manager_resource_group_name>"
$epname = "<endpoint_name_to_be_enabled>"
Enable-AzTrafficManagerEndpoint -name $epname -type "azureEndpoints" -profilename $tmpName -resourcegroupname $tmprgname 
$drname = "<dr_endpoint_name_to_be_deleted>"
Remove-AzTrafficManagerEndpoint -Name $drname -ProfileName $tmpName -ResourceGroupName $tmprgName -Type AzureEndpoints -force
write-Output "Failback Complete"