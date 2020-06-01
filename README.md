<h2>Business Continuity and Disaster Recovery for Azure PaaS</h2>
<h3>Business Case</h3>
While Azure Site Recovery is the recommended solution for IaaS, with PaaS it is not straightforward as just replicating Virtual Machines.
An Enterprise Strategy for PaaS BCDR is needed.
<h3>Solution</h3>
DR for PaaS Services can be classified in 2 types of services:
<ol>
<li>Compute. This includes App Service, Azure Functions, Logic Apps, Azure Automation, Azure Container Instances and Azure Batch.<br>
For these services the strategy is to redeploy. Since there is no disk to care for and the service runs in the fabric, if the RTO can afford a few minutes the best strategy is to re-deploy.
<li>Storage.  This includes Azure Storage, SQL DB, SQL MI, Cosmos DB, etc.<br>
For these services, there is built-in support for BCDR:
<table>
<tr><td>Storage</td><td>Read Access Geo-replication, Storage Failover: https://docs.microsoft.com/en-us/azure/storage/common/storage-disaster-recovery-guidance</td><tr>
<tr><td>SQL DB and MI</td><td>Global Geo-replication. <br>
  https://docs.microsoft.com/en-us/azure/sql-database/sql-database-active-geo-replication<br>
  https://docs.microsoft.com/en-us/azure/sql-database/replication-with-sql-database-managed-instance</td><tr>
<tr><td>Cosmos</td><td>Built-in Global Distribution https://docs.microsoft.com/en-us/azure/cosmos-db/distribute-data-globally</td><tr>
</table>
</ol>
The proposed solution is to enable geo-replication of storage services and redeploy compute.<br>
The solution is cost effective and provides an RTO of minutes and replication-level RPO.   For an RTO that does not tolerate a service redeploy in a different region, a dual deployment is granted.
<h3>Demo Scenario</h3>
This demo presents the design and failover of a Web Application running in an App Service Plan using Azure Key Vault for secrets and a SQL Database for data.
<img src="https://storagegomez.blob.core.windows.net/public/images/PaaSDR.jpg"/>
<hr>
Demo DR For Platform as a Service
To run the demo you will need a Primary environment deployed with:
<ul>
<li>App Service Application in App Service Plan.
<li>App Service using Managed Service Identity. 
<li>SQL Server DB with Geo Replication Enabled and Failover + Group with Secondary in DR Region.
<li>SQL Server failover cnString stored in Key Vault
<li>App enabled to read cnString from Key Vault
<li>Traffic Manager profile with a primary region profile working.
</ul>
The Primary folder has an ARM template that helps with deployment of these artifacts including the SQL Azure DB failover group.

<h3>Solution Failover Implementation Steps:</h3>

1. Create DR ASP, DR Web App with Managed Service Identity (and deploy code).
2. Add DR Web App to Key Vault
3. Perform SQL Azure DB Failover
4. Update Traffic Manager by disabling primary app profile and creating a DR Profile

Solution Files:

<table>
  <tr><th>file</th><th>purpose</th></tr>
  <tr><td>azuredeploy.json</td><td>ARM template for step 1</td></tr>
   <tr><td>automationfailover.ps1</td><td>Azure Automation Runbook that invokes step1 and performs step 2, 3 and 4 with powershell commands.</td></tr>
   <tr><td>failoverwebhook.ps1</td><td>Powershell script that calls the Automation Runbook with a webhook. To be invoked when failing over.</td></tr>
   <tr><td>failback.ps1</td><td>Manual failback Poweshell script</td></tr>
  <tr><td>Primary folder</td><td>ARM Template for the primary (Active) deployment. Including SQL Failover Group</td></tr>
</table>
 



