using namespace System.Net

# Input bindings are passed in via param block.
param (
    $Request,
    $TriggerMetadata
)

#Push-GoodRequest -Body $Request
#return

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

switch ($Request.Method) {
    "get" {
        $id = $Request.Params.id
        $limit = [int]($Request.Query.limit)
    }
    "post" {
        $id = $Request.Body.id
        $limit = [int]($Request.Body.limit)
    }
}

$query = "SELECT * from customers"
$splat = @{}

if ($id) {
    $query = "$query WHERE customer_id = @customer_id"
    $splat.Parameters = @{ customer_id = $id }
}

if ($limit) {
    $query = "$query LIMIT $limit;"
}

Write-Host "Running SQL query: $query"
$results = Invoke-PostgresQuery -Connection (Connect-Postgres) -Query "$query;" @splat

try {
    Push-GoodRequest -Body $results
} catch {
    Push-BadRequest -Body $PSItem
}