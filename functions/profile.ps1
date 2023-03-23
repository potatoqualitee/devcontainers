# Azure Functions profile.ps1
#
# This profile.ps1 will get executed every "cold start" of your Function App.
# "cold start" occurs when:
#
# * A Function App starts up for the very first time
# * A Function App starts up after being de-allocated due to inactivity
#
# You can define helper functions, run commands, or specify environment variables
# NOTE: any variables defined that are not environment variables will get reset after the first execution

Import-Module PSPostgres
$PSDefaultParameterValues["*:EnableException"] = $true
$PSDefaultParameterValues["Connect-Postgres:ConnectionString"] = $env:PGSQLCONN
$PSDefaultParameterValues["*:Confirm"] = $false

# You can also define functions, aliases or script varaibles that can be referenced in any of your PowerShell functions.

# https://learn.microsoft.com/en-us/azure/azure-functions/manage-connections?tabs=csharp

Function Push-GoodRequest {
    [CmdletBinding()]
    param(
        [psobject[]]$Body,
        [hashtable]$Headers
    )

    if ("$Body".Length -eq 1 -or "$Body" -eq "Null" -or $null -eq $Body) {
        Write-Host "Body length is 1 or Null"
        Push-OutputBinding -Name Response -Value (
            [HttpResponseContext]@{
                Headers    = $Headers
                StatusCode = [HttpStatusCode]::OK
                Body       = $Body
            }
        )
    } else {
        Push-OutputBinding -Name Response -Value (
            [HttpResponseContext]@{
                Headers    = $Headers
                StatusCode = [HttpStatusCode]::OK
                Body       = ($Body) | ConvertTo-Json -Compress
            }
        )
    }
}
 
Function Push-BadRequest {
    [CmdletBinding()]
    param(
        [psobject[]]$Body,
        [hashtable]$Headers
    )
    Push-OutputBinding -Name Response -Value (
        [HttpResponseContext]@{
            Headers    = $Headers
            StatusCode = [HttpStatusCode]::BadRequest
            Body       = ($Body) | ConvertTo-Json -Compress
        }
    )
}

Function Invoke-Query {
    [CmdletBinding()]
    param(
        $Statement,
        $Where,
        $OrderBy,
        $Parms
    
    )
    if ($Where) {
        $Where = ($Where -join " and ")
        $flatquery = "$Statement WHERE $Where"
        Write-Host "Query: $flatquery;"
    } else {
        $flatquery = "$Statement"
        Write-Host "No where statement."
        Write-Host "Query: $Statement;"
    }
    
    $splat = @{
        Connection  = Connect-Postgres
        Query       = "$Statement;"
        ErrorAction = "Stop"
    }

    if ($Parms.Keys.Count -gt 0) {
        Write-Host "Passing $($Parms.Keys.Count) parameters"
        $splat.Query = $flatquery
        $splat.Parameters = $Parms
    }

    Invoke-PostgresQuery @splat
}

Function Get-CleanString {
    [CmdletBinding()]
    param(
        [string[]]$Body
    )
    $string = "$Body".Replace(" ", "")
    $string = $string.Replace("`t", "")
    $string = $string.Replace("`r", "")
    $string.Replace("`n", "")
}

function ConvertTo-DotnetDatatype {
    [CmdletBinding()]
    param(
        [psobject]$Value,
        [Parameter(Mandatory)]
        [string]$Table,
        [Parameter(Mandatory)]
        [string]$Schema,
        [Parameter(Mandatory)]
        [string]$Column
    )
    process {
        if (-not $script:columnhash) {
            $query = "SELECT table_catalog, table_schema, table_name, column_name, data_type, udt_name, is_nullable
                      FROM information_schema.columns WHERE table_name IN (SELECT table_name FROM information_schema.tables
                      WHERE table_schema NOT IN ('information_schema', 'pg_catalog') AND table_type = 'BASE TABLE');"
            $script:columnhash = Invoke-PostgresQuery -Connection (Connect-Postgres) -Query $query
        }
        Write-Host "$($script:columnhash.Count) columns retuned"

        if (-not $script:typecsv) {
            $script:typecsv = @{
                timestamp                     = 'DateTime'
                nvarchar                      = 'string'
                varchar                       = 'string'
                bpchar                        = 'char'
                boolean                       = 'bool'
                smallint                      = 'short'
                integer                       = 'int'
                bigint                        = 'long'
                real                          = 'float'
                double                        = 'double'
                numeric                       = 'decimal'
                money                         = 'decimal'
                text                          = 'string'
                'character varying'           = 'string'
                character                     = 'string'
                citext                        = 'string'
                json                          = 'string'
                jsonb                         = 'string'
                xml                           = 'string'
                uuid                          = 'guid'
                bytea                         = 'byte[]'
                'timestamp without time zone' = 'DateTime'
                'timestamp with time zone'    = 'DateTime'
                date                          = 'DateTime'
                'time without time zone'      = 'TimeSpan'
                'time with time zone'         = 'DateTimeOffset'
                interval                      = 'TimeSpan3'
                cidr                          = 'IPAddress'
                inet                          = 'IPAddress'
                macaddr                       = 'PhysicalAddress'
                'bit'                         = 'bool'
                'bit(1)'                      = 'bool'
                'bit(n)'                      = 'BitArray'
                'bit varying'                 = 'BitArray'
                oid                           = 'uint'
                xid                           = 'uint'
                cid                           = 'uint'
                oidvector                     = 'uint[]'
                name                          = 'string'
                geometry                      = 'PostgisGeometry'
                record                        = 'object[]'
                int2                          = 'Int16'
                int4                          = 'Int32'
                int8                          = 'Int64'
            }
        }
        
        Write-Host "Looking for column results from $Schema.$Table"
        
        $results = $script:columnhash.Where({ $PSItem.table_name -eq $Table -and $PSItem.column_name -eq $Column -and $PSItem.table_schema -eq $Schema })

        Write-Host "$($results.count) results from column hash were returned"
        $column = $results.udt_name
        Write-Host "Found the column $column, looking for its type"
        
        $type = $script:typecsv[$column] | Select-Object -First 1
        
        Write-Host "Type for column $column is $type"
        
        if (-not $type) {
            Write-Host "Uh oh! No type for $column. Trying to cast '$Value' to string."
            $type = "String"
        }
        [System.Management.Automation.LanguagePrimitives]::ConvertTo($Value, $type)
    }
}

function ConvertTo-Hashtable {
    [CmdletBinding()]
    [OutputType('hashtable')]
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )
    process {
        if ($null -eq $InputObject) {
            return $null
        }

        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
            $collection = @(
                foreach ($object in $InputObject) {
                    ConvertTo-Hashtable -InputObject $object
                }
            )

            Write-Output -NoEnumerate $collection
        } elseif ($InputObject -is [psobject]) {
            $hash = @{}
            foreach ($property in $InputObject.PSObject.Properties) {
                $hash[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value
            }
            $hash
        } else {
            $InputObject
        }
    }
}

function New-ApiItem {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [psobject[]]$Body,
        [Parameter(Mandatory)]
        [string]$Table
    )
    process {
        $parms = @{}
        $columns = @()
        
        if ((Test-Json -Json "$Body" -ErrorAction SilentlyContinue)) {
            $bodyhash = "$Body" | ConvertFrom-Json | ConvertTo-Hashtable
        } else {
            $bodyhash = $Body | ConvertTo-Json | ConvertFrom-Json | ConvertTo-Hashtable
        }

        $columnlist = $bodyhash.Keys -join ", "
        
        if ($Table -match "\.") {
            $schema = $Table -split "\." | Select-Object -First 1
            $Table = $Table -split "\." | Select-Object -Last 1
        } else {
            $schema = "public"
        }

        foreach ($key in $bodyhash.Keys) {
            Write-Host "Processing $key which has a value of $($bodyhash[$key])"
            $columns += "@$key"
            $parms.$key = ConvertTo-DotnetDatatype -Table $Table -Schema $schema -Column $key -Value $bodyhash[$key]
        }

        $query = "INSERT INTO $schema.$Table ($columnlist) values ($($columns -join ', '))"
        Write-Host "The query is $query"

        [pscustomobject]@{
            Query      = $query
            Parameters = $parms
        }
    }
}

function Update-ApiItem {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [psobject[]]$Body,
        [Parameter(Mandatory)]
        [string]$Table
    )
    process {
        $parms = @{}
        $columns = @()

        if ((Test-Json -Json "$Body" -ErrorAction SilentlyContinue)) {
            $bodyhash = "$Body" | ConvertFrom-Json | ConvertTo-Hashtable
        } else {
            $bodyhash = $Body | ConvertTo-Json | ConvertFrom-Json | ConvertTo-Hashtable
        }
        
        $query = "Update $Table SET"

        if ($Table -match "\.") {
            $schema = $Table -split "\." | Select-Object -First 1
            $Table = $Table -split "\." | Select-Object -Last 1
        } else {
            $schema = "public"
        }
        
        foreach ($key in $bodyhash.Keys) {
            Write-Host "Processing $key which has a value of $($bodyhash[$key])"
            $columns += "$key = @$key"
            $parms.$key = ConvertTo-DotnetDatatype -Table $Table -Schema $schema -Column $key -Value $bodyhash[$key]
        }
        
        $allcolumns = $columns -join ", "
        Write-Host "All columns $allcolumns"

        $query = "$query $allcolumns"
        Write-Host "Query: $query"

        [pscustomobject]@{
            Query      = $query
            Parameters = $parms
        }
    }
}