using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata, $CosmosInput)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."
Write-Host "Total number of candidates: $($CosmosInput.Count)"

# Select the best country
$results = $CosmosInput | Where-Object country -eq "France"
$city = $results.city

Write-output "Results: $resultsName"

# Change the HasWon value for the results in the CosmosDB
$zip = $results.postal_code
$results.postal_code = [int]($results.postal_code)+1
Push-OutputBinding -Name CosmosOutput -Value $results

#Give an HTML output back to the caller
Push-OutputBinding -Name Response -Value (@{
        StatusCode  = [HttpStatusCode]::OK
        ContentType = "text/html"
        Body        = "$city's zip code is $zip"
    })