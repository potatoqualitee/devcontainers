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
$table = "public.customers"
$query = "SELECT customer_id, address, city, company_name, contact_name, contact_title, country, fax, phone, postal_code, region FROM public.customers"

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
        $query = "
        DELETE 
            FROM order_details d
            USING orders o
            WHERE o.order_id = d.order_id
            AND o.customer_id = @customer_id;
        DELETE 
            FROM orders o
            USING customers c
            WHERE o.customer_id = c.customer_id
            AND o.customer_id = @customer_id;
        DELETE
            FROM customers
            WHERE customer_id = @customer_id;"
        $parms.customer_id = $id
    }
}

if ($options -eq "whatever") {
    # this is a placeholder for you
    # to get creative.
}

if ($id -and $Request.Method -ne "delete") {
    $where += "customer_id = @customer_id"
    $parms.customer_id = $id
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