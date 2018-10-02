# PaaSDR
Demo DR For Platform as a Service
To run the demo you will need a Primary environment deployed with:
+ App Service Application in App Service Plan.
+ App Service using Managed Service Identity. 
+ SQL Server DB with Geo Replication Enabled and Failover + Group with Secondary in DR Region.
+ SQL Server failover cnString stored in Key Vault
+ App enabled to read cnString from Key Vault
+ Traffic Manager profile with a primary region profile working.

The Primary folder has an ARM template that helps with deployment of these artifacts but not the SQL Azure DB.

The solution aims to enable a BCDR strategy for a PaaS solution (App Service, SQL Azure DB) with low RPO (relying on Geo Replication) and low RTO (a few minutes).

Solution Failover Implementation Steps:

1. Create ASP, Web App with MSI and deploy code from Github.
2. Add DR App to Key Vault
3. Perform SQL Azure DB Failover
4. Update Traffic Manager by disabling primary app prpfile and creating a DR Profile

Solution Files:

<table>
  <tr><th>file</th><th>purpose</th></tr>
  <tr><td>azuredeploy.json</td><td>ARM template for step 1</td></tr>
   <tr><td>demofailover.ps1</td><td>Azure Automation Runbook that invokes step1 and performs step 2, 3 and 4 with powershell commands.</td></tr>
   <tr><td>failoverwebhook.ps1</td><td>Powershell script that calls the Automation Runbook with a webhook. To be invoked when failing over.</td></tr>
   <tr><td>failback.ps1</td><td>Manual failback Poweshell script</td></tr>
</table>
 
PDF included for clarity.

[Disclaimer: This is work in progress]

