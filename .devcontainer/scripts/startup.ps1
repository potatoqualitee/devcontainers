Set-PSRepository PSGallery -InstallationPolicy Trusted
Install-Module CosmosDB
Import-Module CosmosDB

sudo apt-get update
sudo apt-get install -y ca-certificates curl powershell-lts git

curl --retry 25 --retry-all-errors -k https://localhost:8081/_explorer/emulator.pem
sudo curl -k https://localhost:8081/_explorer/emulator.pem > $home/emulatorcert.crt
$cert = Get-Content $home/emulatorcert.crt | Where-Object { $PSItem -match "BEGIN CERTIFICATE" }

if (-not $cert) {
    echo quit | openssl s_client -showcerts -servername localhost -connect localhost:8081 > $home/emulatorcert.crt
}

Get-Content $home/emulatorcert.crt
sudo cp $home/emulatorcert.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates --fresh

<#

$tables = @{
    "customers" = "customer_id"
    "orders"    = "order_id"
}

foreach ($table in $tables.Keys) {
    $collection = $table -split "\." | Select-Object -Last 1
    $partitionkey = $tables[$table]
    Write-Warning $collection
    Write-Warning $partitionkey
    New-CosmosDbCollection -Context $cosmosDbContext -Database paritycontrol -Id $collection -PartitionKey $partitionkey -ErrorAction Ignore

    $items = Invoke-PostgresQuery -Connection $conn -Query "select * from $table;" 

    foreach ($item in $items) {
        $item.id = $item.$partitionkey
        Write-Warning $item.id
        $collection = $table -split "\." | Select-Object -Last 1
        $json = $item | ConvertTo-Json -EnumsAsStrings
    
        New-CosmosDbDocument -Context $cosmosDbContext -Database paritycontrol -CollectionId $collection -DocumentBody $json -Encoding 'UTF-8' -PartitionKey "$($item.id)"
    }
#>