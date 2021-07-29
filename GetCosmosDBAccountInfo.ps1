cls
$AppsubscriptionId = "Replace the Subscription ID in which the Service Principle was created" 
$appTenantId ="Replace the Tenant Id in which the Service Principle was created"
$appId="Replace the Registered Application Id"
$pwd = "Replace the Scret value created in the Registered Application"

$ExportPath="Replace the path to export "
$SubFileName= $ExportPath + "\" + "SubList.json"
$AccountFileName= $ExportPath + "\" + "CosmosDBAccountList.json"
$DBFileName= $ExportPath + "\" + "CosmosDBDatabaseList.json"
$ContainerFileName=$ExportPath + "\" + "CosmosDBContainerList.json"
$ThroughputFileName=$ExportPath + "\" + "CosmodBDContainerThroughputList.json"

function Delete-Exportfile{


if (Test-Path $SubFileName){
    Remove-Item $SubFileName
    }

if (Test-Path $AccountFileName){
    Remove-Item $AccountFileName
    }

if (Test-Path $DBFileName){
    Remove-Item $DBFileName
    }

if (Test-Path $ContainerFileName){
    Remove-Item $ContainerFileName
    }

if (Test-Path $ThroughputFileName){
    Remove-Item $ThroughputFileName
    }
}


# Authenticate to a specific Azure subscription.

function Get-AuthToken{

    param($p_tenantID)

    $authHeader = @{
    'Content-Type'='application/x-www-form-urlencoded'
'Accept'='*/*'
}

    $clientId = $appId

    $Resource = "https://management.azure.com"
    $RequestAccessTokenUri = "https://login.microsoftonline.com/$p_tenantID/oauth2/token"
 
    $body = "grant_type=client_credentials&client_id=$appId&client_secret=$pwd&resource=$Resource"
 
    # Get Access Token
    $AccessToken = Invoke-RestMethod -Method Post -Uri $RequestAccessTokenUri -Body $body -ContentType 'application/x-www-form-urlencoded' -Headers $authHeader

    #curl -X POST -d 'grant_type=client_credentials&client_id=[APP_ID]&client_secret=[PASSWORD]&resource=https%3A%2F%2Fmanagement.azure.com%2F' https://login.microsoftonline.com/[TENANT_ID]/oauth2/token
    return $AccessToken
}


function Get-ApiKind{
    param([string]$p_apiKind,[string]$p_capabilities)
    
    $apitype="SQL"

    if($p_apiKind.Contains("MongoDB"))
    {
        $apitype="MongoDB"
    }
    else
    {
        if($p_apiKind.Contains("GlobalDocumentDB") -and $p_capabilities.Contains("EnableGremlin"))
        {
             $apitype="Gremlin"
        }
        elseif($p_apiKind.Contains("GlobalDocumentDB") -and $p_capabilities.Contains("EnableTable"))
        {
            $apitype="Table"
        }
        elseif($p_apiKind.Contains("GlobalDocumentDB") -and $p_capabilities.Contains("EnableCassandra"))
        {
            $apitype="Cassandra"
        }
        else
        {
            $apitype="SQL"
        }
    }
    return $apitype
}

function Get-PropertyValue{
 param([string]$p_id, [string]$p_propname)

    $slice = $p_id.Split('/')
     $propindex = 0..($slice.Length -1) | where {$slice[$_] -eq $p_propname}
     $propvalue = $slice.get($propindex+1)
     return $propvalue
 }



function  Get-SubscriptionList{

param($p_tenantId)

$authHeader = @{
'Accept'='*/*'
'Authorization'="Bearer " +  $script:AuthToken.access_token
}

$request = "https://management.azure.com/subscriptions?api-version=2020-01-01"
$SubList = Invoke-RestMethod -Uri $request `
                  -Headers $authHeader `
                  -Method Get `
                  -Verbose 

#$SubList | ConvertTo-Json | Out-File $SubFileName
return $SubList
}

function  Get-CosmosDBAccountList{

param($p_SubId, $p_tenanId)

$authHeader = @{
'Accept'='*/*'
'Authorization'="Bearer " +  $script:AuthToken.access_token
}

$request ="https://management.azure.com/subscriptions/$p_SubId/providers/Microsoft.DocumentDB/databaseAccounts?api-version=2021-04-15"
$AccountList = Invoke-RestMethod -Uri $request `
                  -Headers $authHeader `
                  -Method Get `
                  -Verbose 

#$AccountList.value | ConvertTo-Json -Depth 5 | Out-File $AccountFileName
return $AccountLIst
}


function  Get-CosmosDBDabases{

    param([string]$p_SubId, [string]$p_rgName, [string]$p_AccountName, [string]$p_ApiType)


        $authHeader = @{
        'Accept'='*/*'
        'Authorization'="Bearer " +  $script:AuthToken.access_token
        }

        Write-Information "Api Type -->$p_ApiType" -InformationAction Continue
        if($p_ApiType.Contains("MongoDB"))
        {
            $request ="https://management.azure.com/subscriptions/$p_SubId/resourceGroups/$p_rgName/providers/Microsoft.DocumentDB/databaseAccounts/$p_AccountName/mongodbDatabases?api-version=2021-04-15"
        }
        elseif ($p_ApiType.Contains("SQL"))
        {
            $request ="https://management.azure.com/subscriptions/$p_SubId/resourceGroups/$p_rgName/providers/Microsoft.DocumentDB/databaseAccounts/$p_AccountName/sqlDatabases?api-version=2021-04-15"
        }
        elseif ($p_ApiType.Contains("Gremlin"))
        {
            $request ="https://management.azure.com/subscriptions/$p_SubId/resourceGroups/$p_rgName/providers/Microsoft.DocumentDB/databaseAccounts/$p_AccountName/gremlinDatabases?api-version=2021-04-15"
        }
        elseif($p_ApiType.Contains("Cassandra"))
        {
            $request ="https://management.azure.com/subscriptions/$p_SubId/resourceGroups/$p_rgName/providers/Microsoft.DocumentDB/databaseAccounts/$p_AccountName/cassandraKeyspaces?api-version=2021-04-15"
        }

        $AccountDBList = Invoke-RestMethod -Uri $request `
                          -Headers $authHeader `
                          -Method Get `
                          -Verbose 
        #Write-Output $AccountDBList.value.Count

        #$AccountDBList.value | ConvertTo-Json -Depth 5 | Out-File $DBFileName -Append
        return $AccountDBList
}


function  Get-CosmosDBContainers{

    param([string]$p_SubId, [string]$p_rgName, [string]$p_AccountName, [string]$p_ApiType, [string]$p_dbName)


$authHeader = @{
'Accept'='*/*'
'Authorization'="Bearer " +  $script:AuthToken.access_token
}

        if($p_ApiType.Contains("MongoDB"))
        {
            $request = "https://management.azure.com/subscriptions/$p_SubId/resourceGroups/$p_rgName/providers/Microsoft.DocumentDB/databaseAccounts/$p_AccountName/mongodbDatabases/$p_dbName/collections?api-version=2021-04-15"
                        
        }
        elseif ($p_ApiType.Contains("SQL"))
        {

            $request ="https://management.azure.com/subscriptions/$p_SubId/resourceGroups/$p_rgName/providers/Microsoft.DocumentDB/databaseAccounts/$p_AccountName/sqlDatabases/$p_dbName/containers?api-version=2021-04-15"
             
        }
        elseif ($p_ApiType.Contains("Gremlin"))
        {
            $request ="https://management.azure.com/subscriptions/$p_SubId/resourceGroups/$p_rgName/providers/Microsoft.DocumentDB/databaseAccounts/$p_AccountName/gremlinDatabases/$p_dbName/graphs?api-version=2021-04-15"
        }
        elseif($p_ApiType.Contains("Cassandra"))
        {
            $request ="https://management.azure.com/subscriptions/$p_SubId/resourceGroups/$p_rgName/providers/Microsoft.DocumentDB/databaseAccounts/$p_AccountName/cassandraKeyspaces/$p_dbName/tables?api-version=2021-04-15"
        }
        elseif($p_ApiType.Contains("Table"))
        {
            $request = "https://management.azure.com/subscriptions/$p_SubId/resourceGroups/$p_rgName/providers/Microsoft.DocumentDB/databaseAccounts/$p_AccountName/Tables?api-version=2021-04-15"
        }

$ContainerList = Invoke-RestMethod -Uri $request `
                  -Headers $authHeader `
                  -Method Get `
                  -Verbose 


#$ContainerList | ConvertTo-Json | Out-File $ContainerFileName -Append
return $ContainerList
}


function Get-Databases{
    
    $script:DatabaseList  = New-Object System.Collections.ArrayList
    foreach($aitem in $script:AccountList)
    {
        $subid = Get-PropertyValue $aitem.id "subscriptions"
        $resourcegroupname = Get-PropertyValue $aitem.id "resourceGroups"
        
        $capabilities = $aitem.properties.capabilities | ConvertTo-Json -Depth 5
        $apiKind= Get-ApiKind $aitem.kind $capabilities
        
        if(!$apiKind.contains("Table"))
        {
            $local:results = Get-CosmosDBDabases $subid $resourcegroupname $aitem.name $apiKind
        
            foreach($dbitem in $local:results.value)
            {
                $script:DatabaseList.Add($dbitem)  
            }
        }
    }
  
   #$script:DatabaseList | ConvertTo-Json -Depth 5 | Out-File $DBFileName
  
}

function Get-CosmosDBDatabaseAccounts{
    param($p_subids)
    $script:AccountList =New-Object System.Collections.ArrayList
    

    foreach($item in $p_subids.value)
    {

        Write-Information $item.subscriptionId.ToString() -InformationAction Continue
        $local:results =Get-CosmosDBAccountList $item.subscriptionId $item.tenantId

        foreach($Accountitem in $local:results.value)
        {
            $script:AccountList.Add($Accountitem)  
        }
    }
   #$script:AccountList | ConvertTo-Json -Depth 5 | Out-File $AccountFileName
   
}

function Get-CosmosDBDatabaseAccountInfo{
    param($p_SubId, $p_resourcegroupname,$p_AccountName)

    $authHeader = @{
    'Accept'='*/*'
    'Authorization'="Bearer " +  $script:AuthToken.access_token
    }
    $request = "https://management.azure.com/subscriptions/$p_SubId/resourceGroups/$p_resourcegroupname/providers/Microsoft.DocumentDB/databaseAccounts/$p_AccountName" + "?api-version=2021-04-15"
    $local:AccountInfo = Invoke-RestMethod -Uri $request `
                  -Headers $authHeader `
                  -Method Get `
                  -Verbose 

    return $local:AccountInfo
}



function Get-Containers{
    
    $script:ContainerList  = New-Object System.Collections.ArrayList
    foreach($ditem in $script:DatabaseList)
    {
        $subid = Get-PropertyValue $ditem.id "subscriptions"
        $resourcegroupname = Get-PropertyValue $ditem.id "resourceGroups"
        $accountname  = Get-PropertyValue  $ditem.id "databaseAccounts"
        $local:Accountinfo = Get-CosmosDBDatabaseAccountInfo $subid $resourcegroupname $accountname        

        $local:capabilities =  $local:Accountinfo.properties.capabilities | ConvertTo-Json -Depth 5

        $apiKind= Get-ApiKind $local:Accountinfo.kind $local:capabilities
        if(!$apiKind.contains("Table"))
        {
            #param([string]$p_SubId, [string]$p_rgName, [string]$p_AccountName, [string]$p_ApiType, [string]$p_dbName)

            $local:results = Get-CosmosDBContainers $subid $resourcegroupname $accountname  $apiKind $ditem.name 
        

            foreach($collitem in $local:results.value)
            {
                $script:ContainerList.Add($collitem)  
            }
        }
        else
        {
            Write-Debug "Enumerating Database List, Invalid API Kind:Table found" -WarningAction Continue
        }
    }

  
     #Table API does not ahve database. Enumerate directly the tables.

    foreach($aitem in $script:AccountList)
    {
        $subid = Get-PropertyValue $aitem.id "subscriptions"
        $resourcegroupname = Get-PropertyValue $aitem.id "resourceGroups"
        $accountname  = Get-PropertyValue  $aitem.id "databaseAccounts"
        $capabilities = $aitem.properties.capabilities | ConvertTo-Json -Depth 5
        $apiKind= Get-ApiKind $aitem.kind  $capabilities

        if($apiKind.contains("Table"))
        {
        
            #get Tables from Table API.  NO Database Name exists.

            $local:tables = Get-CosmosDBContainers $subid $resourcegroupname $accountname  $apiKind "Tables"
            foreach($collitem in $local:tables.value)
            {
                $script:ContainerList.Add($collitem)  
            }
            
        }
    }


  $script:ContainerList
}

function Get-ThroughputRequest{
    param([string]$p_id, [string]$p_type, [string]$p_throughputtype)
  
        $subid = Get-PropertyValue $p_id "subscriptions"
        $resourcegroupname = Get-PropertyValue $p_id "resourceGroups"
        $accountname  = Get-PropertyValue  $p_id "databaseAccounts"
        
        $local:Accountinfo = Get-CosmosDBDatabaseAccountInfo $subid $resourcegroupname $accountname        

        $local:capabilities =  $local:Accountinfo.properties.capabilities | ConvertTo-Json -Depth 5

        $apiKind= Get-ApiKind $local:Accountinfo.kind $local:capabilities


        if($apiKind.contains("SQL"))
        {
            $dbname  = Get-PropertyValue  $p_id "sqlDatabases"
            $cname  = Get-PropertyValue  $p_id "containers"
            if($p_throughputtype.contains("Container"))
            {
                $request ="https://management.azure.com/subscriptions/$subid/resourceGroups/$resourcegroupname/providers/Microsoft.DocumentDB/databaseAccounts/$accountname/sqlDatabases/$dbname/containers/$cname/throughputSettings/default?api-version=2021-04-15"
                           
            }
            else
            {

                $request ="https://management.azure.com/subscriptions/$subid/resourceGroups/$resourcegroupname/providers/Microsoft.DocumentDB/databaseAccounts/$accountname/sqlDatabases/$dbname/throughputSettings/default?api-version=2021-04-15"

            }
        }
        elseif($apiKind.contains("MongoDB"))
        {
            $dbname  = Get-PropertyValue  $p_id "mongodbDatabases"
            $cname  = Get-PropertyValue  $p_id "collections"

            if($p_throughputtype.contains("Container"))   
            { 
                $request = "https://management.azure.com/subscriptions/$subid/resourceGroups/$resourcegroupname/providers/Microsoft.DocumentDB/databaseAccounts/$accountname/mongodbDatabases/$dbname/collections/$cname/throughputSettings/default?api-version=2021-04-15"
            }
            else
            {
                $request = "https://management.azure.com/subscriptions/$subid/resourceGroups/$resourcegroupname/providers/Microsoft.DocumentDB/databaseAccounts/$accountname/mongodbDatabases/$dbname/throughputSettings/default?api-version=2021-04-15"
            }
        }
        elseif($apiKind.contains("Gremlin"))
        {
            $dbname  = Get-PropertyValue  $p_id "gremlinDatabases"
            $cname  = Get-PropertyValue  $p_id "graphs"

            if($p_throughputtype.contains("Container"))
            {
                $request = "https://management.azure.com/subscriptions/$subid/resourceGroups/$resourcegroupname/providers/Microsoft.DocumentDB/databaseAccounts/$accountname/gremlinDatabases/$dbname/graphs/$cname/throughputSettings/default?api-version=2021-04-15"
            }
            else
            {
                $request = "https://management.azure.com/subscriptions/$subid/resourceGroups/$resourcegroupname/providers/Microsoft.DocumentDB/databaseAccounts/$accountname/gremlinDatabases/$dbname/throughputSettings/default?api-version=2021-04-15"
                        
            }

        }
        elseif($apiKind.contains("Cassandra"))
        {
            $dbname  = Get-PropertyValue  $p_id "cassandraKeyspaces"
            $cname  = Get-PropertyValue  $p_id "tables"

            if($p_throughputtype.contains("Container"))
            {
                
                $request = "https://management.azure.com/subscriptions/$subid/resourceGroups/$resourcegroupname/providers/Microsoft.DocumentDB/databaseAccounts/$accountname/cassandraKeyspaces/$dbname/tables/$cname/throughputSettings/default?api-version=2021-04-15"
            }
            else
            {
                $request = "https://management.azure.com/subscriptions/$subid/resourceGroups/$resourcegroupname/providers/Microsoft.DocumentDB/databaseAccounts/$accountname/cassandraKeyspaces/$dbname/throughputSettings/default?api-version=2021-04-15"
                        
            }

        }
        elseif($apiKind.contains("Table"))
        {
            $cname  = Get-PropertyValue  $p_id "tables"

            $request = "https://management.azure.com/subscriptions/$subid/resourceGroups/$resourcegroupname/providers/Microsoft.DocumentDB/databaseAccounts/$accountname/tables/$cname/throughputSettings/default?api-version=2021-04-15"

        }
    return $request
}

function Get-DatabaseContainerThroughput{
    
    $script:Containerthroughput  = New-Object System.Collections.ArrayList

  $authHeader = @{
        'Accept'='*/*'
        'Authorization'="Bearer " +  $script:AuthToken.access_token
        }


    foreach($ditem in $script:ContainerList)
    {
       
        $request= Get-ThroughputRequest $ditem.id $ditem.type "Container"
        
        try
        {
            $throughput = Invoke-RestMethod -Uri $request `
                  -Headers $authHeader `
                  -Method Get `
                  -Verbose 
        
            $script:Containerthroughput.Add($throughput)  
        }
        catch {
            if($_.ErrorDetails.Message.contains("NotFound") ) {
                $msg = "Resource Id:$ditem.Id, $_.ErrorDetails.Message"

                #Write-Information $msg -InformationAction continue
                Write-Warning $msg -WarningAction Continue
                $request= Get-ThroughputRequest $ditem.id $ditem.type "Database"

                $throughput = Invoke-RestMethod -Uri $request `
                  -Headers $authHeader `
                  -Method Get `
                  -Verbose 
                $Dbexist = $script:Containerthroughput | Where-Object{$_.id -eq $throughput.Id}
                if($null -eq ($script:Containerthroughput | Where-Object{$_.id -eq $throughput.Id}))
                {
                    $script:Containerthroughput.Add($throughput)
                }
                else
                {
                    $msg = "Skipping to add the Container RU since its Shared Throuhgput"
                    Write-Warning $msg -WarningAction Continue

                }
                

            }

        }

    }

  



   
  $script:Containerthroughput
}

function Export-CosmosDBInfo{

    $script:sublist.value  | ConvertTo-Json -Depth 5 | Out-File $SubFileName
    $script:AccountList | ConvertTo-Json -Depth 5 | Out-File $AccountFileName
    $script:DatabaseList | ConvertTo-Json -Depth 5 | Out-File $DBFileName
    $script:ContainerList | ConvertTo-Json -Depth 8 | Out-File $ContainerFileName
    $script:Containerthroughput | ConvertTo-Json -Depth 8 | Out-File $ThroughputFileName
}

#Main function

    #cleanup any exported files

    Delete-Exportfile

    $script:AuthToken=Get-AuthToken $appTenantId

    $script:sublist = Get-SubscriptionList $AppsubscriptionId

    Get-CosmosDBDatabaseAccounts $script:sublist

    Get-Databases

    Get-Containers

    Get-DatabaseContainerThroughput

    Export-CosmosDBInfo

