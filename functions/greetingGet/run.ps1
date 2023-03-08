using namespace System.Net

# Input bindings are passed in via param block.
param (
    $Request,
    $TriggerMetadata
)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

switch ($Request.Method) {
    "get" {
        $name = $Request.Params.name
    }
    "post" {
        $name = $Request.Body.name
    }
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
if ($name) {
    Push-OutputBinding -Name Response -Value (
        [HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body       = "Ayyy, you did it, $name!" | ConvertTo-Json -Depth 5
        }
    )
} else {
    Push-OutputBinding -Name Response -Value (
        [HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::BadRequest
            Body       = "Name required" | ConvertTo-Json -Depth 5
        }
    )
}