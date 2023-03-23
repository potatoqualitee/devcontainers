Describe "Integration Tests" -Tag "IntegrationTests" {
    It "gets a bunch of customers" {
        $results = Invoke-RestMethod -Uri http://localhost:7071/v1/customers
        ($results).Count | Should -BeGreaterThan 10
        ($results | Where-Object customer_id -eq 'BLONP').country | Should -Be "France"
    }
    
    It "gets a specific customer" {
        $results = Invoke-RestMethod -Uri http://localhost:7071/v1/customers/BLONP
        $results.country | Should -Be "France"
    }

    It "adds a customer" {
        $body = @{
            customer_id   = "POTAT"
            address       = "100 Rue du Nord"
            city          = "Paris"
            company_name  = "Potato Enterprises"
            contact_name  = "Kitty LeMaire"
            contact_title = "Sales Representative"
            country       = "France"
            fax           = "030-0076545"
            phone         = "030-0074321"
            postal_code   = "12209"
            region        = $null
        } | ConvertTo-Json

        { Invoke-RestMethod -Uri http://localhost:7071/v1/customers -Method POST -Body $body -ErrorAction Stop } | Should -Not -Throw

        $results = Invoke-RestMethod -Uri http://localhost:7071/v1/customers/POTAT
        $results.customer_id | Should -BeExactly "POTAT"
    }

    It "updates a customer" {
        $body = @{
            contact_name   = 'Kitty Cankles'
            contact_title  = 'Senior Sales Representative'
        } | ConvertTo-Json

        { Invoke-RestMethod -Uri http://localhost:7071/v1/customers/POTAT -Method PATCH -Body $body -ErrorAction Stop } | Should -Not -Throw

        $results = Invoke-RestMethod -Uri http://localhost:7071/v1/customers/POTAT
        $results.contact_name | Should -BeExactly "Kitty Cankles"
    }

    It "deletes one customer and does not modify any others" {
        Invoke-RestMethod -Method DELETE -Uri http://localhost:7071/v1/customers/POTAT
        $results = Invoke-RestMethod -Uri http://localhost:7071/v1/customers/POTAT
        $results | Should -BeNullOrEmpty
        
        $results = Invoke-RestMethod -Uri http://localhost:7071/v1/customers/BLONP
        $results.customer_id | Should -Be "BLONP"
        $results.postal_code | Should -Be 67000
    }

}