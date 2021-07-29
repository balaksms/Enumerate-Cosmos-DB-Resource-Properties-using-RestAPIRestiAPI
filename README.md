# Sample script to query Cosmos DB Resource properties through Rest API


Azure Cosmos DB offer multiple database APIs which include the Core(SQL) API, API for MongoDB, Cassandra API, Gremlin API and Table API. 
Cosmos DB resource can be managed using powershell or CLI which may not be preferable for all users.  This sample uses the Rest API to enumerate the resource properties 
non-interactively by using Azure AD Service principal by generating access token based on the permission granted to the Service principal. The script generates Json output files
with all properties for a given resource and resource type on which the Service principal have read permission.

## Use cases
Administrator or Business owner can lookup up any specific properties through simple Json lookup or flaten the json file for reporting purposes or automating a work flow.

## Steps to run the script


1. [Register an application with Azure AD and create a service principal](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal#register-an-application-with-azure-ad-and-create-a-service-principal)
2. [Grant Reader Permission to Service Principle](https://docs.microsoft.com/en-us/azure/cosmos-db/role-based-access-control#identity-and-access-management-iam)
3. Execute the sample Script 
4. The script creates the below json files 
   - Tenant and Subscription Ids 
   - Accounts Information in CosmosDBAccountList.json
   - Databases Information in CosmosDBDatabaseList.json
   - Container Information in CosmosDBContainerList.json
   - Database and Container Throughput Information in CosmodBDContainerThroughputList.json


## References
1. [Azure Cosmos DB Resource Provider REST API](https://docs.microsoft.com/en-us/rest/api/cosmos-db-resource-provider/)
2. [Azure CLI for Azure Cosmos DB](https://docs.microsoft.com/en-us/cli/azure/azure-cli-reference-for-cosmos-db)
3. [Azure PowerShell samples for Azure Cosmos DB Core (SQL) AP](https://docs.microsoft.com/en-us/azure/cosmos-db/powershell-samples)
