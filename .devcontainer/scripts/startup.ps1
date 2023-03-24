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


$tables = @{
    order_details = "order_id"
    orders        = "order_id"
    customers     = "order_id"
    products      = "order_id"
    suppliers     = "order_id"
    employees     = "order_id"
}

$cosmosDbContext = New-CosmosDbContext -Emulator
New-CosmosDbDatabase -Context $cosmosDbContext -Id Northwind

foreach ($collection in $tables.Keys) {
    $partitionkey = $tables[$collection]
    Write-Warning $collection
    Write-Warning $partitionkey

    $parms = @{
        Context      = $cosmosDbContext
        Database     = "Northwind"
        Id           = $collection
        PartitionKey = $partitionkey
        ErrorAction  = "Ignore"
    }

    #New-CosmosDbCollection @parms

    foreach ($item in (Get-ChildItem ./tests/json/$collection)) {
        Write-Warning $item.FullName
        $json = Get-Content -Raw -Path $item.FullName
        $parms = @{
            Context      = $cosmosDbContext
            Database     = "Northwind"
            CollectionId = $collection
            DocumentBody = $json
            Encoding     = "UTF-8"
            PartitionKey = $partitionkey
        }
        New-CosmosDbDocument @parms
    }
}

