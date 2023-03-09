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

# Authenticate with Azure PowerShell using MSI.
# Remove this if you are not planning on using MSI or Azure PowerShell.

# Import-Module Az.Accounts -RequiredVersion '1.9.5'

if ($env:MSI_SECRET -and (Get-Module -ListAvailable Az.Accounts)) {
    Connect-AzAccount -Identity
}


Import-Module PSPostgres
$PSDefaultParameterValues["*:EnableException"] = $true
$PSDefaultParameterValues["Connect-Postgres:ConnectionString"] = $env:PGSQLCONN
$PSDefaultParameterValues["*:Confirm"] = $false

# You can also define functions, aliases or script varaibles that can be referenced in any of your PowerShell functions.

# https://learn.microsoft.com/en-us/azure/azure-functions/manage-connections?tabs=csharp

Function Push-GoodRequest {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [psobject[]]$Body
    )
    Push-OutputBinding -Name Response -Value (
        [HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body       = ($Body) | ConvertTo-Json -Compress
        }
    )
}
 
Function Push-BadRequest {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [psobject[]]$Body
    )
    Push-OutputBinding -Name Response -Value (
        [HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::BadRequest
            Body       = ($Body) | ConvertTo-Json -Compress
        }
    )
}