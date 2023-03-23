using namespace System.Net

# Input bindings are passed in via param block.
param (
    $Request,
    $TriggerMetadata
)
# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a customer request."

$parms = @{}
$where = @()
$table = "public.suppliers"
$query = "SELECT supplier_id, company_name, contact_name, contact_title, address, city, region, postal_code, country, phone, fax, homepage FROM public.suppliers"

$id = $Request.Params.id
$options = $Request.Params.options

switch ($Request.Method) {
    "post" {
        $prep = New-ApiItem -Body $Request.Body -Table $table
        $query = $prep.Query
        $parms = $prep.Parameters
    }
    "patch" {
        $prep = Update-ApiItem -Body $Request.Body -Table $table
        $query = $prep.Query
        $parms = $prep.Parameters
    }
    "delete" {
        # usually this is a straightforward query
        # but the db is relational with no cascading
        $query = "DELETE FROM public.suppliers"
    }
}

if ($options -eq "whatever") {
    # this is a placeholder for you
    # to get creative.
}

if ($id) {
    $where += "supplier_id = @supplier_id"
    $parms.supplier_id = [int]$id
}

try {
    $splat = @{
        Statement   = $query
        Where       = $where
        OrderBy     = $orderby
        Parms       = $parms
        ErrorAction = "Stop"
    }
    Push-GoodRequest -Body (Invoke-Query @splat)
} catch {
    Push-BadRequest -Body "$PSItem"
}