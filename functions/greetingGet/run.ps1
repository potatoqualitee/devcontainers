using namespace System.Net

# Input bindings are passed in via param block.
param (
    $Request,
    $TriggerMetadata
)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

$httpResponse = [HttpResponseContext]@{}

if ($Request.Body.Name) {
    $name = $Request.Body.Name
} elseif ($Request.Query.Name) {
    $name = $Request.Query.Name
} else {
    $body = "Name required"

    $httpResponse.StatusCode = [HttpStatusCode]::BadRequest
    $httpResponse.Body = $body

    Push-OutputBinding -Name Response -Value $httpResponse
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value (
    [HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = "Heyyy you did it, $name!" | ConvertTo-Json -Depth 5
    }
)